# Cap'n Proto RPC Server (FR-015, FR-016, FR-017)
# Provides server-side RPC functionality

using Sockets

"""
    ExportEntry

Extended export table entry with promise metadata for Level 2.
Tracks whether an export is a promise awaiting resolution.
"""
struct ExportEntry
    capability::Any           # The actual capability
    ref_count::UInt32         # Reference count from remote
    is_promise::Bool          # True if this is a promise export
    promise_id::Union{ExportId,Nothing}  # Link to promise if resolved from one
end

"""
Create a regular (non-promise) export entry.
"""
function ExportEntry(capability::Any, ref_count::UInt32 = UInt32(1))
    ExportEntry(capability, ref_count, false, nothing)
end

"""
Create a promise export entry.
"""
function promise_export_entry(capability, promise_id::ExportId)
    ExportEntry(capability, UInt32(1), true, promise_id)
end

# Note: PromisedExport is defined in connection.jl for proper include order

"""
    ServerOptions

Configuration options for RPC servers.

`tcp_nodelay` controls the `TCP_NODELAY` socket option on the TCP listener and
on every accepted connection, including TLS listeners served through the Reseau
extension. It defaults to `true`, matching the reference Cap'n Proto
implementation, and is ignored for Unix-domain listeners.
"""
struct ServerOptions
    max_connections::Int
    max_message_size::Int
    max_segments::Int
    traversal_limit_words::Int
    nesting_limit::Int
    inbound_queue_size::Int
    outbound_queue_size::Int
    max_questions::Int
    max_answers::Int
    max_exports::Int
    max_imports::Int
    tcp_nodelay::Bool

    function ServerOptions(;
        max_connections::Int = 1000,
        max_message_size::Int = Capnp.DEFAULT_MAX_MESSAGE_SIZE,
        max_segments::Int = Capnp.DEFAULT_MAX_SEGMENTS,
        traversal_limit_words::Int = Capnp.DEFAULT_TRAVERSAL_LIMIT_WORDS,
        nesting_limit::Int = Capnp.DEFAULT_NESTING_LIMIT,
        inbound_queue_size::Int = 64,
        outbound_queue_size::Int = 64,
        max_questions::Int = 1024,
        max_answers::Int = 1024,
        max_exports::Int = 8192,
        max_imports::Int = 8192,
        tcp_nodelay::Bool = DEFAULT_TCP_NODELAY,
    )
        max_connections > 0 || throw(ArgumentError("max_connections must be positive"))
        Capnp._validate_reader_limits(max_message_size, max_segments)
        Capnp._validate_traversal_limits(traversal_limit_words, nesting_limit)
        _validate_connection_limits(inbound_queue_size, outbound_queue_size, max_questions, max_answers, max_exports, max_imports)
        new(max_connections, max_message_size, max_segments, traversal_limit_words, nesting_limit, inbound_queue_size, outbound_queue_size, max_questions, max_answers, max_exports, max_imports, tcp_nodelay)
    end
end

"""
    CallContext

Context passed to server method implementations.
Contains connection info and methods to set results or exceptions.
"""
mutable struct CallContext
    connection::Connection
    question_id::QuestionId
    interface_id::UInt64
    method_id::UInt16
    result::Any
    has_exception::Bool
    exception_reason::String
    exception_type::ExceptionType.T
    result_caps::Vector{ExportId}
    # Pointer slot of the results struct -> capability placed there, filled in by
    # write_capability!. Lets pipelined calls name the right capability when the
    # results struct mixes capabilities with other fields.
    result_cap_slots::Dict{UInt16,ExportId}

    function CallContext(conn::Connection, qid::QuestionId, iface_id::UInt64, method_id::UInt16)
        new(conn, qid, iface_id, method_id, nothing, false, "", ExceptionType.FAILED, ExportId[], Dict{UInt16,ExportId}())
    end
end

"""
    set_result!(ctx::CallContext, result)

Set the result of an RPC call.

`result` must be one of the shapes [`build_return_message`](@ref) can put on the
wire:

- an `ExportId` from [`export_capability`](@ref), returning that capability;
- a [`ResultsBuilder`](@ref) from [`set_results!`](@ref), for any other shape;
- an `AbstractString`, returning a `Text` field in pointer slot 0;
- a scalar in [`SCALAR_RESULT_TYPES`](@ref), which keeps its own type on the wire;
- `nothing`, for a method that answers with no value.

Anything else raises, rather than being coerced into a number the caller never
asked for. The call is answered with an exception, since dispatch runs inside the
server's error handling.

Note that `ExportId` is an alias for `UInt32`, so a bare `UInt32` always means
"return this capability". Use [`set_results!`](@ref) to return a `UInt32` field.
"""
function set_result!(ctx::CallContext, result)
    _check_result_shape(result)
    ctx.result = result
    ctx.has_exception = false
end

_check_result_shape(::Nothing) = nothing
_check_result_shape(::ExportId) = nothing
_check_result_shape(::AbstractString) = nothing
_check_result_shape(::ResultsBuilder) = nothing
_check_result_shape(::SCALAR_RESULT_TYPES) = nothing
# Level 2 persistence results. They are accepted because the server already
# produces them, but they have no wire encoding yet and go out as a zero-filled
# data word, so a client cannot actually read back a SturdyRef.
_check_result_shape(::ParsedSaveResults) = nothing
_check_result_shape(::ParsedRestoreResults) = nothing
_check_result_shape(result) = throw(
    ArgumentError("Cannot return a result of type $(typeof(result)). Supported results are " * "an ExportId, a ResultsBuilder, an AbstractString, one of $(SCALAR_RESULT_TYPES), " * "or nothing. Use set_results! to build any other shape."),
)

"""
    set_exception!(ctx::CallContext, reason::String, type::ExceptionType.T)

Set an exception for an RPC call.
"""
function set_exception!(ctx::CallContext, reason::String, type::ExceptionType.T)
    ctx.has_exception = true
    ctx.exception_reason = reason
    ctx.exception_type = type

    # Cleanup any result capabilities exported before the exception
    for cap_id in ctx.result_caps
        cap = get_export(ctx.connection, cap_id)
        if cap !== nothing && decref!(cap)
            remove_export!(ctx.connection, cap_id)
        end
    end
    empty!(ctx.result_caps)
    empty!(ctx.result_cap_slots)
end

"""
    set_results!(ctx::CallContext, build::Function; data_word_count = 0, pointer_count = 0)
    set_results!(build::Function, ctx::CallContext; data_word_count = 0, pointer_count = 0)

Answer the call with a results struct of the given shape, written by `build`.

This is the general form of [`set_result!`](@ref), and the server-side mirror of
the `params_builder` a client passes to [`call`](@ref): `build` is invoked as
`build(results_ptr, pointer_location)` with a `Capnp.StructPointer` of the
requested shape, and fills in whatever the method's return type declares. Use
[`write_capability!`](@ref) to place a capability in one of the pointer slots.

The second form supports `do` blocks:

```julia
function Calculator_stats(impl::MyCalculator, ctx::RPC.CallContext, params)
    RPC.set_results!(ctx; data_word_count = 1, pointer_count = 1) do results, _
        Capnp.write_bits(results, 0, UInt64, impl.call_count)
        set_name!(results, impl.name, Val{:StatsResults})
    end
end
```
"""
function set_results!(ctx::CallContext, build::Function; data_word_count::Integer = 0, pointer_count::Integer = 0)
    set_result!(ctx, ResultsBuilder(UInt16(data_word_count), UInt16(pointer_count), build))
    return nothing
end

set_results!(build::Function, ctx::CallContext; data_word_count::Integer = 0, pointer_count::Integer = 0) = set_results!(ctx, build; data_word_count, pointer_count)

"""
    write_capability!(ctx::CallContext, results_ptr, pointer_index::Integer, impl, interface_id::UInt64) -> ExportId

Export `impl` and place it in pointer slot `pointer_index` of `results_ptr`.

Exports the capability on the connection, appends the matching `senderHosted`
descriptor to the message's capability table, and writes the capability pointer
that refers to it. Doing all three together is what keeps the pointer indices
and the capability table in step, so prefer this over calling
[`export_capability`](@ref) and writing the pointer separately.

Only meaningful from inside a [`set_results!`](@ref) callback, where
`results_ptr` belongs to the message being built.
"""
function write_capability!(ctx::CallContext, results_ptr, pointer_index::Integer, impl, interface_id::UInt64)
    export_id = export_capability(ctx, impl, interface_id)
    traverser = results_ptr.traverser
    push!(traverser.capabilities, ParsedCapDescriptor(CapDescriptorType.SENDER_HOSTED, sender_hosted = export_id))
    cap_index = UInt32(length(traverser.capabilities) - 1)
    location = Capnp.WirePointer(results_ptr.segment, results_ptr.offset + results_ptr.data_word_count + pointer_index)
    Capnp.write_capability_pointer(location, traverser, cap_index)
    ctx.result_cap_slots[UInt16(pointer_index)] = export_id
    return export_id
end

"""
    export_capability(ctx::CallContext, impl, interface_id::UInt64) -> ExportId

Export a capability to be returned to the client.
"""
function export_capability(ctx::CallContext, impl, interface_id::UInt64)
    eid = next_export_id!(ctx.connection)
    cap = LocalCapability(interface_id, impl)
    add_export!(ctx.connection, eid, cap)
    push!(ctx.result_caps, eid)
    return eid
end

"""
    Server

RPC server that listens for connections and dispatches method calls.
Supports Level 2 persistent capabilities via an optional restorer.
"""
mutable struct Server
    bootstrap_impl::Any
    connection_handler::Union{Function,Nothing}
    clients::Vector{Connection}
    options::ServerOptions
    is_running::Bool
    listener_task::Union{Task,Nothing}
    tcp_server::Any
    lock::ReentrantLock
    # Level 2: Restorer for persistent capabilities
    restorer::Union{DefaultRestorer,Nothing}

    function Server(bootstrap_impl; handler::Union{Function,Nothing} = nothing, options::ServerOptions = ServerOptions(), restorer::Union{DefaultRestorer,Nothing} = nothing)
        new(bootstrap_impl, handler, Connection[], options, false, nothing, nothing, ReentrantLock(), restorer)
    end

    # Support do-block syntax: Server(impl) do conn ... end
    function Server(handler::Function, bootstrap_impl; options::ServerOptions = ServerOptions(), restorer::Union{DefaultRestorer,Nothing} = nothing)
        new(bootstrap_impl, handler, Connection[], options, false, nothing, nothing, ReentrantLock(), restorer)
    end
end

# State accessors
is_running(server::Server) = server.is_running

function set_running!(server::Server, running::Bool)
    lock(server.lock) do
        server.is_running = running
    end
end

# Client management
function client_count(server::Server)
    lock(server.lock) do
        length(server.clients)
    end
end

function add_client!(server::Server, conn::Connection)
    lock(server.lock) do
        push!(server.clients, conn)
    end
end

function remove_client!(server::Server, conn::Connection)
    lock(server.lock) do
        filter!(c -> c !== conn, server.clients)
    end
end

function get_clients(server::Server)
    lock(server.lock) do
        copy(server.clients)
    end
end

"""
    listen(server::Server, host::AbstractString, port::Integer)

Start listening for TCP connections on the specified host and port.

`TCP_NODELAY` is applied to the listener and to every accepted socket unless
`ServerOptions(tcp_nodelay = false)` was used.
"""
function listen(server::Server, host::AbstractString, port::Integer)
    listener = Sockets.listen(Sockets.IPv4(host), port)
    set_tcp_nodelay!(listener, server.options.tcp_nodelay)
    server.tcp_server = listener
    set_running!(server, true)
    return server
end

"""
    listen(server::Server, socket_path::AbstractString)

Start listening for Unix domain socket connections.
"""
function listen(server::Server, socket_path::AbstractString)
    # Remove existing socket file if it exists
    isfile(socket_path) && rm(socket_path)
    server.tcp_server = Sockets.listen(socket_path)
    set_running!(server, true)
    return server
end

"""
    serve(server::Server)

Start the server's accept loop. This function blocks and handles incoming connections.
"""
function serve(server::Server)
    if server.tcp_server === nothing
        error("Server not listening. Call listen() first.")
    end

    set_running!(server, true)

    try
        while is_running(server)
            try
                socket = accept(server.tcp_server)
                handle_new_connection(server, socket)
            catch e
                if e isa EOFError || !is_running(server)
                    break
                end
                @warn "Error accepting connection" exception=e
            end
        end
    finally
        set_running!(server, false)
    end
end

"""
    serve_async(server::Server) -> Task

Start the server's accept loop in a background task.
"""
function serve_async(server::Server)
    server.listener_task = @async serve(server)
    return server.listener_task
end

"""
    handle_new_connection(server::Server, socket)

Handle a new incoming connection.
"""
function handle_new_connection(server::Server, socket)
    # Check max connections
    if client_count(server) >= server.options.max_connections
        close(socket)
        return
    end

    # Create transport and connection
    transport = if socket isa Sockets.TCPSocket
        TcpTransport(
            socket;
            max_message_size = server.options.max_message_size,
            max_segments = server.options.max_segments,
            traversal_limit_words = server.options.traversal_limit_words,
            nesting_limit = server.options.nesting_limit,
            nodelay = server.options.tcp_nodelay,
        )
    else
        UnixTransport(socket, ""; max_message_size = server.options.max_message_size, max_segments = server.options.max_segments, traversal_limit_words = server.options.traversal_limit_words, nesting_limit = server.options.nesting_limit)
    end
    conn = Connection(
        transport;
        owns_transport = true,
        inbound_queue_size = server.options.inbound_queue_size,
        outbound_queue_size = server.options.outbound_queue_size,
        max_questions = server.options.max_questions,
        max_answers = server.options.max_answers,
        max_exports = server.options.max_exports,
        max_imports = server.options.max_imports,
    )

    # Call connection handler if set
    if server.connection_handler !== nothing
        if !server.connection_handler(conn)
            close(conn)
            return
        end
    end

    # Mark as connected and add to clients
    set_connected!(conn)
    add_client!(server, conn)

    # Start client handler task
    @async handle_client(server, conn)
end

"""
    handle_client(server::Server, conn::Connection)

Handle messages from a connected client.
"""
function handle_client(server::Server, conn::Connection)
    conn.message_handler = (c, m) -> handle_server_message!(server, c, m)
    start_message_loop!(conn)
    # wait for the connection to close
    try
        wait(conn.process_task)
    catch e
        if !(e isa TaskFailedException && (e.task.exception isa EOFError || e.task.exception isa DisconnectedException))
            @warn "Error handling client" exception=e
        end
    finally
        remove_client!(server, conn)
        close(conn)
    end
end

"""
    handle_server_message!(server::Server, conn::Connection, message)

Process an incoming RPC message on the server side.
Parses the RPC message type and dispatches to appropriate handler.
"""
function handle_server_message!(server::Server, conn::Connection, message::Capnp.MessageReader)
    try
        # Parse the incoming RPC message
        parsed = parse_rpc_message(message)

        if parsed.type == MessageType.BOOTSTRAP
            handle_bootstrap_message!(server, conn, parsed.bootstrap)
        elseif parsed.type == MessageType.CALL
            handle_call_message!(server, conn, parsed.call)
        elseif parsed.type == MessageType.FINISH
            handle_finish_message!(conn, parsed.finish)
        elseif parsed.type == MessageType.RELEASE
            handle_release_message!(conn, parsed.release)
        else
            # Send unimplemented response for unsupported message types
            @warn "Received unsupported RPC message type" type=parsed.type
        end
    catch e
        for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        end
    end
end

"""
    handle_bootstrap_message!(server::Server, conn::Connection, bootstrap::ParsedBootstrap)

Handle a Bootstrap message - export the root capability and send Return.
"""
function handle_bootstrap_message!(server::Server, conn::Connection, bootstrap::ParsedBootstrap)
    # Export the bootstrap capability
    export_id = handle_bootstrap(server, conn)

    # Build and send Return message with the capability
    response = build_bootstrap_return(bootstrap.question_id, export_id)
    queue_message!(conn, response)
end

"""
    _resolve_call_target(conn::Connection, target::ParsedMessageTarget) -> (cap, refusal)

Find the capability a Call names, or explain why it cannot be found.

Returns the `LocalCapability` and an empty string on success, or `nothing` and a
reason on failure. There is deliberately no fallback: substituting some other
capability for one that cannot be resolved answers a question the caller never
asked, and the caller has no way to tell.
"""
function _resolve_call_target(conn::Connection, target::ParsedMessageTarget)
    if target.kind == MessageTargetType.IMPORTED_CAP
        target.imported_cap === nothing && return nothing, "Call names no message target"
        cap = get_export(conn, ExportId(target.imported_cap))
        cap === nothing && return nothing, "No capability is exported as $(target.imported_cap)"
        return cap, ""
    end

    if target.kind != MessageTargetType.PROMISED_ANSWER
        return nothing, "Unsupported message target $(target.kind)"
    end

    pa = target.promised_answer
    pa === nothing && return nothing, "Call targets a promised answer but names none"

    answer = get_answer(conn, pa.question_id)
    answer === nothing && return nothing, "No pending answer for question $(pa.question_id); it may already have been finished"

    export_id = nothing
    if !isempty(pa.transform) && pa.transform[1].kind == PromisedAnswerOpType.GET_POINTER_FIELD && pa.transform[1].get_pointer_field !== nothing
        idx = pa.transform[1].get_pointer_field
        if !isempty(answer.cap_slots)
            # The answer knows its layout: the slot either holds a capability or
            # it does not, and guessing is worse than reporting nothing.
            export_id = get(answer.cap_slots, UInt16(idx), nothing)
            export_id === nothing && return nothing, "Answer for question $(pa.question_id) has no capability in pointer slot $(idx)"
        elseif (idx + 1) <= length(answer.result_caps)
            # Older answers only record the capabilities, not where they sit, so
            # fall back to their order.
            export_id = answer.result_caps[idx+1]
        else
            return nothing, "Answer for question $(pa.question_id) returned $(length(answer.result_caps)) capabilities, none at position $(idx)"
        end
    elseif !isempty(answer.result_caps)
        # No usable transform: the caller means the answer's only capability.
        export_id = answer.result_caps[1]
    else
        return nothing, "Answer for question $(pa.question_id) returned no capability to call"
    end

    cap = get_export(conn, export_id)
    cap === nothing && return nothing, "Capability $(export_id) named by question $(pa.question_id) is no longer exported"
    return cap, ""
end

"""
    handle_call_message!(server::Server, conn::Connection, call::ParsedCall)

Handle a Call message - dispatch to method implementation and send Return.
Includes Level 2 support for Persistent.save() calls.
"""
function handle_call_message!(server::Server, conn::Connection, call::ParsedCall)
    # Create call context
    ctx = CallContext(conn, call.question_id, call.interface_id, call.method_id)

    cap, refusal = _resolve_call_target(conn, call.target)

    if cap === nothing
        set_exception!(ctx, refusal, ExceptionType.FAILED)
    else
        # Check if this is a Persistent.save() call (Level 2)
        if is_save_call(call)
            handle_save_call!(server, conn, ctx, cap, call)
        else
            # Dispatch the call to the implementation
            try
                dispatch_method!(cap.impl, call.interface_id, call.method_id, ctx, call.params)
            catch e
                if e isa RemoteException
                    set_exception!(ctx, e.reason, e.type)
                else
                    set_exception!(ctx, string(e), ExceptionType.FAILED)
                end
            end
        end
    end

    # Store the answer so pipelined calls can find it
    # A bare ExportId result puts its capability in pointer slot 0
    cap_slots = if ctx.result isa ExportId
        Dict{UInt16,ExportId}(UInt16(0) => ctx.result)
    else
        ctx.result_cap_slots
    end
    answer = PendingAnswer(ctx.question_id, ctx.result_caps, UInt32(0); cap_slots)
    answer.result = ctx.result
    add_answer!(conn, answer)

    # Send Return message
    send_return_response!(conn, ctx)
end

"""
    dispatch_method!(impl, interface_id::UInt64, method_id::UInt16, ctx::CallContext, params)

Dispatch a method call to the implementation.
This function should be overridden by generated code or user implementations.
"""
function dispatch_method!(impl, interface_id::UInt64, method_id::UInt16, ctx::CallContext, params)
    # Default implementation - try to call a method based on naming convention
    # Generated code will provide proper dispatch

    # Try to find a dispatch function for this interface
    method_name = Symbol("dispatch_$(interface_id)_$(method_id)")
    if isdefined(Main, method_name)
        getfield(Main, method_name)(impl, ctx, params)
    else
        set_exception!(ctx, "Method not found: interface=$interface_id method=$method_id", ExceptionType.UNIMPLEMENTED)
    end
end



"""
    send_return_response!(conn::Connection, ctx::CallContext)

Build and send a Return message based on the call context.
"""
function send_return_response!(conn::Connection, ctx::CallContext)
    response = build_return_message(ctx.question_id, ctx.result; has_exception = ctx.has_exception, exception_reason = ctx.exception_reason)
    queue_message!(conn, response)
end

"""
    handle_finish_message!(conn::Connection, finish::ParsedFinish)

Handle a Finish message - clean up the answer.
"""
function handle_finish_message!(conn::Connection, finish::ParsedFinish)
    handle_finish!(conn, finish.question_id, finish.release_result_caps)
end

"""
    handle_release_message!(conn::Connection, release::ParsedRelease)

Handle a Release message - decrement capability reference count.
"""
function handle_release_message!(conn::Connection, release::ParsedRelease)
    handle_server_release!(conn, ExportId(release.id), release.reference_count)
end

"""
    handle_bootstrap(server::Server, conn::Connection) -> ExportId

Handle a Bootstrap message - return the root capability.
"""
function handle_bootstrap(server::Server, conn::Connection)
    # Export the bootstrap capability
    eid = next_export_id!(conn)
    cap = LocalCapability(UInt64(0), server.bootstrap_impl)  # Interface ID 0 for bootstrap
    add_export!(conn, eid, cap)
    return eid
end

"""
    handle_call!(server::Server, conn::Connection, target, interface_id::UInt64, method_id::UInt16, params, question_id::QuestionId)

Handle a Call message - dispatch to the appropriate method implementation.
"""
function handle_call!(server::Server, conn::Connection, target, interface_id::UInt64, method_id::UInt16, params, question_id::QuestionId)
    # Create call context
    ctx = CallContext(conn, question_id, interface_id, method_id)

    # Find the capability to call
    cap = nothing
    if target isa UInt32
        # ImportedCap - look up in exports
        cap = get_export(conn, target)
    end

    if cap === nothing
        set_exception!(ctx, "Invalid capability", ExceptionType.FAILED)
        return send_return!(conn, ctx)
    end

    # Dispatch the call
    try
        # The actual dispatch would call the generated method dispatcher
        # dispatch_interface(cap.impl, interface_id, method_id, ctx, params)
        error("Method dispatch not yet implemented")
    catch e
        if e isa RemoteException
            set_exception!(ctx, e.reason, e.type)
        else
            set_exception!(ctx, string(e), ExceptionType.FAILED)
        end
    end

    # Send return message
    send_return!(conn, ctx)
end

"""
    send_return!(conn::Connection, ctx::CallContext)

Send a Return message for a completed call.
"""
function send_return!(conn::Connection, ctx::CallContext)
    # Build and send Return message
    # In a full implementation, this would serialize the result or exception
    # into a Cap'n Proto Return message and send it over the transport
    return nothing
end

"""
    handle_finish!(conn::Connection, question_id::QuestionId, release_caps::Bool)

Handle a Finish message - clean up the answer entry.
"""
function handle_finish!(conn::Connection, question_id::QuestionId, release_caps::Bool)
    answer = get_answer(conn, question_id)
    if answer !== nothing
        if release_caps
            # Release any capabilities in the result
            for cap_id in answer.result_caps
                cap = get_export(conn, cap_id)
                if cap !== nothing && decref!(cap)
                    remove_export!(conn, cap_id)
                end
            end
        end
        remove_answer!(conn, question_id)
    end
end

"""
    handle_release!(conn::Connection, id::ExportId, ref_count::UInt32)

Handle a Release message - decrement reference count on exported capability.
"""
function handle_server_release!(conn::Connection, id::ExportId, ref_count::UInt32)
    cap = get_export(conn, id)
    if cap !== nothing
        for _ = 1:ref_count
            if decref!(cap)
                remove_export!(conn, id)
                break
            end
        end
    end
end

"""
    send_resolve!(conn::Connection, promise_id::ExportId, export_id::ExportId)

Send a Resolve message to notify the client that a promised capability has resolved.
This implements the server-side of C001-RESOLVE contract.

Called when:
1. A capability was exported as senderPromise (promised export)
2. The underlying promise resolves to an actual capability
"""
function send_resolve!(conn::Connection, promise_id::ExportId, export_id::ExportId)
    # Build and send the Resolve message
    # The resolved capability uses senderHosted to indicate it's now fully available
    message = build_resolve_message(promise_id, CapDescriptorType.SENDER_HOSTED, export_id)
    queue_message!(conn, message)
end

"""
    send_resolve_exception!(conn::Connection, promise_id::ExportId, reason::String, exc_type::ExceptionType.T)

Send a Resolve message with an exception when a promised capability fails to resolve.
"""
function send_resolve_exception!(conn::Connection, promise_id::ExportId, reason::String, exc_type::ExceptionType.T)
    message = build_resolve_exception(promise_id, reason, exc_type)
    queue_message!(conn, message)
end

"""
    export_promised_capability!(ctx::CallContext, promise::Promise{Any}, interface_id::UInt64) -> ExportId

Export a capability that is still a promise (not yet resolved).
Uses senderPromise in the CapDescriptor and sets up a callback to send Resolve when it settles.

This is used when a method returns a capability that isn't immediately available.
"""
function export_promised_capability!(ctx::CallContext, promise::Promise{Any}, interface_id::UInt64)
    conn = ctx.connection
    eid = next_export_id!(conn)

    # Track this as a promised export
    add_promised_export!(conn, eid, promise)

    # Set up callback to send Resolve when the promise settles
    on_resolve!(promise, function (resolved_cap)
        # Export the resolved capability with a new ID
        new_eid = next_export_id!(conn)
        cap = LocalCapability(interface_id, resolved_cap)
        add_export!(conn, new_eid, cap)

        # Send Resolve to client
        send_resolve!(conn, eid, new_eid)

        # Clean up promised export tracking
        remove_promised_export!(conn, eid)
    end)

    on_reject!(promise, function (err)
        # Send Resolve with exception
        reason = err isa Exception ? string(err) : string(err)
        exc_type = err isa RemoteException ? err.type : ExceptionType.FAILED
        send_resolve_exception!(conn, eid, reason, exc_type)

        # Clean up promised export tracking
        remove_promised_export!(conn, eid)
    end)

    return eid
end


# ============================================================================
# Level 2: Server-Side Persistent Capability Handling
# ============================================================================

"""
    set_restorer!(server::Server, restorer::DefaultRestorer)

Configure the server's restorer for persistent capabilities.
"""
function set_restorer!(server::Server, restorer::DefaultRestorer)
    lock(server.lock) do
        server.restorer = restorer
    end
end

"""
    get_restorer(server::Server) -> Union{DefaultRestorer, Nothing}

Get the server's restorer for persistent capabilities.
"""
function get_restorer(server::Server)
    lock(server.lock) do
        return server.restorer
    end
end

"""
    handle_save_call!(server::Server, conn::Connection, ctx::CallContext, cap)

Handle a Persistent.save() call on a capability.
This implements C004-SERVER-PERSISTENCE contract.

If the capability is persistent, generates a SturdyRef and returns it.
If not persistent, returns an UNIMPLEMENTED exception.
"""
function handle_save_call!(server::Server, conn::Connection, ctx::CallContext, cap, call::ParsedCall)
    # Check if we have a restorer configured
    restorer = get_restorer(server)
    if restorer === nothing
        set_exception!(ctx, "Server does not support persistent capabilities", ExceptionType.UNIMPLEMENTED)
        return
    end

    # Get the actual capability (unwrap LocalCapability if needed)
    impl = cap isa LocalCapability ? cap.impl : cap

    # Check if the capability is persistent
    if !is_persistent(impl)
        set_exception!(ctx, "Capability does not implement Persistent interface", ExceptionType.UNIMPLEMENTED)
        return
    end

    # Extract sealFor from params (it's the first pointer in SaveParams)
    seal_for = nothing
    if call.params !== nothing && call.params.pointer_count >= 1
        # Extract the AnyPointer
        seal_for = Capnp.read_struct_pointer(call.params, 0, 0)
    end

    # Check if the owner can save this capability
    if !can_save(impl, seal_for)
        set_exception!(ctx, "Owner not authorized to save this capability", ExceptionType.FAILED)
        return
    end

    # Generate the SturdyRef
    try
        sturdy_ref = generate_sturdy_ref(impl, seal_for, restorer)
        # Serialize the SturdyRef as the result
        result_data = serialize_sturdy_ref(sturdy_ref)
        set_result!(ctx, ParsedSaveResults(result_data))
    catch e
        set_exception!(ctx, "Failed to generate SturdyRef: $(string(e))", ExceptionType.FAILED)
    end
end

"""
    handle_restore_call!(server::Server, conn::Connection, ctx::CallContext, sturdy_ref_data::Vector{UInt8})

Handle a restore call from a client.
Looks up the capability in the restorer and exports it.
"""
function handle_restore_call!(server::Server, conn::Connection, ctx::CallContext, sturdy_ref_data::Vector{UInt8})
    restorer = get_restorer(server)
    if restorer === nothing
        set_exception!(ctx, "Server does not support persistent capabilities", ExceptionType.UNIMPLEMENTED)
        return
    end

    # Deserialize the SturdyRef
    try
        sturdy_ref = deserialize_sturdy_ref(sturdy_ref_data)
        owner = DefaultOwner()  # TODO: Extract owner from params

        # Restore the capability
        capability = restore(restorer, sturdy_ref, owner)

        # Export the restored capability
        export_id = export_capability(ctx, capability, UInt64(0))
        set_result!(ctx, ParsedRestoreResults(true, export_id, nothing, nothing))
    catch e
        if e isa RestoreException
            set_exception!(ctx, e.reason, ExceptionType.FAILED)
        else
            set_exception!(ctx, "Restore failed: $(string(e))", ExceptionType.FAILED)
        end
    end
end

"""
    register_persistent!(server::Server, object_id::Vector{UInt8}, capability, owner::DefaultOwner) -> Union{DefaultSturdyRef, Nothing}

Register a capability as persistent in the server's restorer.
Returns the SturdyRef, or nothing if no restorer is configured.
"""
function register_persistent!(server::Server, object_id::Vector{UInt8}, capability, owner::DefaultOwner = DefaultOwner())
    restorer = get_restorer(server)
    if restorer === nothing
        return nothing
    end
    return register!(restorer, object_id, capability, owner)
end

"""
    is_save_call(call::ParsedCall) -> Bool

Check if a Call message is a Persistent.save() call.
"""
function is_save_call(call::ParsedCall)
    return call.interface_id == PERSISTENT_INTERFACE_ID && call.method_id == PERSISTENT_SAVE_METHOD_ID
end

"""
    shutdown!(server::Server)

Gracefully shutdown the server and all client connections.
"""
function shutdown!(server::Server)
    set_running!(server, false)

    # Close all client connections
    clients = get_clients(server)
    for conn in clients
        close(conn)
    end

    # Clear client list
    lock(server.lock) do
        empty!(server.clients)
    end

    # Close the listener
    if server.tcp_server !== nothing
        close(server.tcp_server)
        server.tcp_server = nothing
    end
end

# Exports
export Server, ServerOptions, CallContext
export ExportEntry, promise_export_entry
export is_running, set_running!, client_count, add_client!, remove_client!
export listen, serve, serve_async, shutdown!
export set_result!, set_results!, set_exception!, export_capability, write_capability!, export_promised_capability!
export handle_bootstrap, handle_call!, handle_finish!, handle_server_release!
export send_resolve!, send_resolve_exception!

# Level 2: Server-side persistence exports
export set_restorer!, get_restorer
export handle_save_call!, handle_restore_call!
export register_persistent!, is_save_call

"""
    listen(server::Server, host::AbstractString, port::Integer, tls_config::TLSListenerConfig)

Listen for incoming TLS-secured Cap'n Proto RPC connections.
Requires the `Reseau` package to be loaded.
"""
function listen(server::Server, host::AbstractString, port::Integer, tls_config::AbstractTLSListenerConfig)
    error("TLS listeners require the Reseau package to be loaded. Run `using Reseau`.")
end
