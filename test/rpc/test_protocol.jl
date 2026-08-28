# Tests for RPC Protocol message parsing and building (Level 2)
# T014-T015: parse_resolve() and build_resolve_message() tests

using Test
using Capnp
using Capnp.RPC

@testset "RPC Protocol Level 2" begin
    @testset "ResolveType enum" begin
        # Module-scoped enum per constitution
        @test RPC.ResolveType.CAP isa RPC.ResolveType.T
        @test RPC.ResolveType.EXCEPTION isa RPC.ResolveType.T

        # Values are distinct
        @test RPC.ResolveType.CAP != RPC.ResolveType.EXCEPTION
    end

    @testset "CapDescriptorType enum" begin
        @test RPC.CapDescriptorType.NONE isa RPC.CapDescriptorType.T
        @test RPC.CapDescriptorType.SENDER_HOSTED isa RPC.CapDescriptorType.T
        @test RPC.CapDescriptorType.SENDER_PROMISE isa RPC.CapDescriptorType.T
        @test RPC.CapDescriptorType.RECEIVER_HOSTED isa RPC.CapDescriptorType.T
        @test RPC.CapDescriptorType.RECEIVER_ANSWER isa RPC.CapDescriptorType.T
    end

    @testset "PromisedAnswerOpType enum" begin
        @test RPC.PromisedAnswerOpType.NOOP isa RPC.PromisedAnswerOpType.T
        @test RPC.PromisedAnswerOpType.GET_POINTER_FIELD isa RPC.PromisedAnswerOpType.T
    end

    @testset "ParsedResolve struct" begin
        # Test resolve with capability
        cap_descriptor = RPC.ParsedCapDescriptor(
            RPC.CapDescriptorType.SENDER_HOSTED,
            UInt32(42),  # sender_hosted export ID
            nothing,     # sender_promise
            nothing,     # receiver_hosted
            nothing,      # receiver_answer
        )

        resolve_cap = RPC.ParsedResolve(
            UInt32(1),           # promise_id
            RPC.ResolveType.CAP, # kind
            cap_descriptor,      # cap_descriptor
            nothing,             # exception_reason
            nothing,              # exception_type
        )

        @test resolve_cap.promise_id == UInt32(1)
        @test resolve_cap.kind == RPC.ResolveType.CAP
        @test resolve_cap.cap_descriptor !== nothing
        @test resolve_cap.cap_descriptor.sender_hosted == UInt32(42)

        # Test resolve with exception
        resolve_exception = RPC.ParsedResolve(
            UInt32(2),                 # promise_id
            RPC.ResolveType.EXCEPTION, # kind
            nothing,                   # cap_descriptor
            "capability failed",       # exception_reason
            RPC.ExceptionType.FAILED,   # exception_type
        )

        @test resolve_exception.promise_id == UInt32(2)
        @test resolve_exception.kind == RPC.ResolveType.EXCEPTION
        @test resolve_exception.cap_descriptor === nothing
        @test resolve_exception.exception_reason == "capability failed"
        @test resolve_exception.exception_type == RPC.ExceptionType.FAILED
    end

    @testset "ParsedCapDescriptor struct" begin
        # SENDER_HOSTED
        sender_hosted = RPC.ParsedCapDescriptor(RPC.CapDescriptorType.SENDER_HOSTED, UInt32(10), nothing, nothing, nothing)
        @test sender_hosted.kind == RPC.CapDescriptorType.SENDER_HOSTED
        @test sender_hosted.sender_hosted == UInt32(10)

        # SENDER_PROMISE
        sender_promise = RPC.ParsedCapDescriptor(RPC.CapDescriptorType.SENDER_PROMISE, nothing, UInt32(20), nothing, nothing)
        @test sender_promise.kind == RPC.CapDescriptorType.SENDER_PROMISE
        @test sender_promise.sender_promise == UInt32(20)

        # RECEIVER_HOSTED
        receiver_hosted = RPC.ParsedCapDescriptor(RPC.CapDescriptorType.RECEIVER_HOSTED, nothing, nothing, UInt32(30), nothing)
        @test receiver_hosted.kind == RPC.CapDescriptorType.RECEIVER_HOSTED
        @test receiver_hosted.receiver_hosted == UInt32(30)

        # NONE
        none_cap = RPC.ParsedCapDescriptor(RPC.CapDescriptorType.NONE, nothing, nothing, nothing, nothing)
        @test none_cap.kind == RPC.CapDescriptorType.NONE
    end

    @testset "PromisedAnswerOp struct" begin
        # NOOP operation
        noop = RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.NOOP, nothing)
        @test noop.kind == RPC.PromisedAnswerOpType.NOOP
        @test noop.get_pointer_field === nothing

        # GET_POINTER_FIELD operation
        get_field = RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(3))
        @test get_field.kind == RPC.PromisedAnswerOpType.GET_POINTER_FIELD
        @test get_field.get_pointer_field == UInt16(3)
    end

    @testset "ParsedPromisedAnswer struct" begin
        ops = [RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(0)), RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(1))]
        promised = RPC.ParsedPromisedAnswer(UInt32(5), ops)

        @test promised.question_id == UInt32(5)
        @test length(promised.transform) == 2
        @test promised.transform[1].get_pointer_field == UInt16(0)
        @test promised.transform[2].get_pointer_field == UInt16(1)
    end

    @testset "build_resolve_message" begin
        # Test building resolve with capability (SENDER_HOSTED)
        # These functions return raw bytes for transmission
        bytes = RPC.build_resolve_message(UInt32(42), RPC.CapDescriptorType.SENDER_HOSTED, UInt32(100))
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
    end

    @testset "Bootstrap and Return exchange" begin
        request_bytes = RPC.build_bootstrap_request(UInt32(17))
        request = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(request_bytes)))
        @test request.type == RPC.MessageType.BOOTSTRAP
        @test request.bootstrap.question_id == UInt32(17)

        response_bytes = RPC.build_bootstrap_return(UInt32(17), UInt32(23))
        response = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(response_bytes)))
        @test response.type == RPC.MessageType.RETURN
        @test response.return_msg.answer_id == UInt32(17)
        @test response.return_msg.kind == RPC.ReturnType.RESULTS
        @test response.return_msg.cap_table[1].kind == RPC.CapDescriptorType.SENDER_HOSTED
        @test response.return_msg.cap_table[1].sender_hosted == UInt32(23)

        exception_bytes = RPC.build_exception_return(UInt32(17), "bootstrap denied", RPC.ExceptionType.FAILED)
        exception_response = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(exception_bytes)))
        @test exception_response.return_msg.kind == RPC.ReturnType.EXCEPTION
        @test exception_response.return_msg.exception_reason == "bootstrap denied"
        @test exception_response.return_msg.exception_type == RPC.ExceptionType.FAILED
    end

    @testset "Text results" begin
        # A results struct with a single Text field in pointer slot 0
        function read_result_text(payload)
            results = Capnp.read_struct_pointer(payload, 0, 0)
            Capnp.read_text(Capnp.read_list_pointer(results, results.data_word_count, 0))
        end

        for text in ("", "x", "(x-1)*(x+1)", "é\u00e0\u20ac", "a"^7, "a"^8, "a"^9, "a"^100_000)
            bytes = RPC.build_text_return(UInt32(31), text)
            @test length(bytes) % 8 == 0
            parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(bytes)))
            @test parsed.type == RPC.MessageType.RETURN
            @test parsed.return_msg.answer_id == UInt32(31)
            @test parsed.return_msg.kind == RPC.ReturnType.RESULTS
            @test isempty(parsed.return_msg.cap_table)
            @test read_result_text(parsed.return_msg.payload_ptr) == text
        end

        # build_return_message dispatches strings to build_text_return
        via_dispatch = RPC.build_return_message(UInt32(31), "routed")
        @test via_dispatch == RPC.build_text_return(UInt32(31), "routed")

        # SubString and other AbstractStrings are accepted
        @test RPC.build_return_message(UInt32(31), SubString("prefix-routed", 8)) == via_dispatch

        # An exception takes precedence over a string result
        raised = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(RPC.build_return_message(UInt32(31), "ignored"; has_exception = true, exception_reason = "boom"))))
        @test raised.return_msg.kind == RPC.ReturnType.EXCEPTION
        @test raised.return_msg.exception_reason == "boom"
    end

    @testset "Unresolvable call targets are refused, never substituted" begin
        mock = RPC.MockTransport()
        conn = RPC.Connection(mock)
        impl = "bootstrap"
        bootstrap_id = RPC.next_export_id!(conn)
        RPC.add_export!(conn, bootstrap_id, RPC.LocalCapability(UInt64(0), impl))

        # The bootstrap is reachable when actually named
        cap, refusal = RPC._resolve_call_target(conn, RPC.ParsedMessageTarget(RPC.MessageTargetType.IMPORTED_CAP, bootstrap_id))
        @test cap !== nothing
        @test refusal == ""

        # Export id 0 is reserved, so a zeroed id names nothing
        @test bootstrap_id != RPC.ExportId(0)
        for (target, fragment) in [
            (RPC.ParsedMessageTarget(RPC.MessageTargetType.IMPORTED_CAP, nothing), "names no message target"),
            (RPC.ParsedMessageTarget(RPC.MessageTargetType.IMPORTED_CAP, RPC.ImportId(0)), "No capability is exported"),
            (RPC.ParsedMessageTarget(RPC.MessageTargetType.IMPORTED_CAP, RPC.ImportId(999)), "No capability is exported"),
            (RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, nothing), "names none"),
            (RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, RPC.ParsedPromisedAnswer(UInt32(77), RPC.PromisedAnswerOp[])), "No pending answer"),
        ]
            cap, refusal = RPC._resolve_call_target(conn, target)
            @test cap === nothing
            @test occursin(fragment, refusal)
        end

        # An answer that returned no capability cannot be pipelined on
        RPC.add_answer!(conn, RPC.PendingAnswer(UInt32(88)))
        cap, refusal = RPC._resolve_call_target(conn, RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, RPC.ParsedPromisedAnswer(UInt32(88), RPC.PromisedAnswerOp[])))
        @test cap === nothing
        @test occursin("no capability to call", refusal)

        # An answer whose pointer slot 1 holds no capability is refused rather
        # than resolved to the capability that happens to sit elsewhere
        other = RPC.next_export_id!(conn)
        RPC.add_export!(conn, other, RPC.LocalCapability(UInt64(0), "elsewhere"))
        RPC.add_answer!(conn, RPC.PendingAnswer(UInt32(89), RPC.ExportId[other], UInt32(0); cap_slots = Dict{UInt16,RPC.ExportId}(UInt16(0) => other)))
        slot_one = RPC.ParsedPromisedAnswer(UInt32(89), [RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(1))])
        cap, refusal = RPC._resolve_call_target(conn, RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, slot_one))
        @test cap === nothing
        @test occursin("no capability in pointer slot 1", refusal)

        # ... while slot 0 still resolves
        slot_zero = RPC.ParsedPromisedAnswer(UInt32(89), [RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(0))])
        cap, refusal = RPC._resolve_call_target(conn, RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, slot_zero))
        @test cap !== nothing
        @test cap.impl == "elsewhere"
    end

    @testset "A Call with no target names nothing" begin
        # parse_message_target used to invent importedCap = 0 here, which is a
        # real capability, so a targetless Call was answered by the bootstrap.
        segment = zeros(UInt8, 64)
        target = RPC.parse_message_target(segment, 1)
        @test target.kind == RPC.MessageTargetType.IMPORTED_CAP
        @test target.imported_cap === nothing
    end

    @testset "Scalar results keep their type" begin
        results(bytes) = Capnp.read_struct_pointer(RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(bytes))).return_msg.payload_ptr, 0, 0)

        cases = [
            (UInt64(2)^60 + 1, UInt64),   # not representable as Float64
            (typemax(UInt64), UInt64),
            (Int64(-7), Int64),
            (typemin(Int64), Int64),
            (Int32(-3), Int32),
            (UInt16(0xffff), UInt16),
            (Int16(-32768), Int16),
            (UInt8(255), UInt8),
            (Int8(-128), Int8),
            (true, Bool),
            (false, Bool),
            (2.5f0, Float32),
            (2.5, Float64),
        ]
        for (value, T) in cases
            @test Capnp.read_bits(results(RPC.build_return_message(UInt32(1), value)), 0, T) == value
        end

        # A method that set no result answers with a zero-filled data word
        @test Capnp.read_bits(results(RPC.build_return_message(UInt32(1), nothing)), 0, UInt64) == 0
    end

    @testset "Unsupported results are refused, not coerced" begin
        mock = RPC.MockTransport()
        conn = RPC.Connection(mock)
        ctx = RPC.CallContext(conn, UInt32(1), UInt64(0x1234), UInt16(0))

        # Accepted shapes
        for value in (nothing, RPC.ExportId(3), "text", UInt64(9), Int32(-1), true, 1.5)
            RPC.set_result!(ctx, value)
            @test ctx.result == value
        end
        RPC.set_result!(ctx, RPC.ResultsBuilder(UInt16(0), UInt16(0), (p, l) -> nothing))
        @test ctx.result isa RPC.ResultsBuilder

        # Refused shapes, which used to be silently sent as 0.0
        @test_throws ArgumentError RPC.set_result!(ctx, :a_symbol)
        @test_throws ArgumentError RPC.set_result!(ctx, [1, 2, 3])
        @test_throws ArgumentError RPC.set_result!(ctx, Int128(1))
        @test_throws ArgumentError RPC.set_result!(ctx, 1 // 2)
    end

    @testset "ResultsBuilder shapes" begin
        results(bytes) = Capnp.read_struct_pointer(RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(bytes))).return_msg.payload_ptr, 0, 0)

        # A void return: no data words, no pointers
        void_bytes = RPC.build_results_return(UInt32(5), RPC.ResultsBuilder(UInt16(0), UInt16(0), (p, l) -> nothing))
        parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(void_bytes)))
        @test parsed.return_msg.answer_id == UInt32(5)
        @test parsed.return_msg.kind == RPC.ReturnType.RESULTS
        @test isempty(parsed.return_msg.cap_table)

        # Data words and Text pointers side by side
        mixed = RPC.ResultsBuilder(UInt16(2), UInt16(2), function (res, _)
            Capnp.write_bits(res, 0, UInt64, UInt64(0xdeadbeef))
            Capnp.write_bits(res, 8, Float64, 2.5)
            for (i, text) in enumerate(("first", "second and longer"))
                loc = Capnp.WirePointer(res.segment, res.offset + res.data_word_count + (i - 1))
                loc, seg, off = Capnp.alloc(res.traverser, loc, ncodeunits(text) + 1)
                child = Capnp.SimpleListPointer{UInt8,typeof(res.traverser)}(res.traverser, seg, off, Capnp.Byte, UInt32(ncodeunits(text) + 1))
                Capnp.write_list_pointer(loc, child)
                Capnp.write_text(child, text)
            end
        end)
        r = results(RPC.build_results_return(UInt32(9), mixed))
        @test Capnp.read_bits(r, 0, UInt64) == 0xdeadbeef
        @test Capnp.read_bits(r, 8, Float64) == 2.5
        @test Capnp.read_text(Capnp.read_list_pointer(r, r.data_word_count, 0)) == "first"
        @test Capnp.read_text(Capnp.read_list_pointer(r, r.data_word_count, 1)) == "second and longer"

        # build_return_message routes a ResultsBuilder here
        rb = RPC.ResultsBuilder(UInt16(1), UInt16(0), (res, _) -> Capnp.write_bits(res, 0, UInt64, UInt64(11)))
        @test RPC.build_return_message(UInt32(9), rb) isa Vector{UInt8}
    end

    @testset "Call target round-trip" begin
        # MessageTarget.importedCap sits at byte 4 of the target struct. Writing it
        # anywhere else makes every call land on the peer's bootstrap capability.
        target = RPC.ParsedMessageTarget(RPC.MessageTargetType.IMPORTED_CAP, RPC.ImportId(7))
        builder = RPC.build_call(UInt32(9), target, UInt64(0x1122), UInt16(0), (p, l) -> nothing)
        io = IOBuffer()
        Capnp.writeMessageToStream(builder, io)
        parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(take!(io))))
        @test parsed.type == RPC.MessageType.CALL
        @test parsed.call.target.kind == RPC.MessageTargetType.IMPORTED_CAP
        @test parsed.call.target.imported_cap == RPC.ImportId(7)
    end

    @testset "PromisedAnswer transform round-trip" begin
        ops = [RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(1)), RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.NOOP, nothing), RPC.PromisedAnswerOp(RPC.PromisedAnswerOpType.GET_POINTER_FIELD, UInt16(3))]
        target = RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, RPC.ParsedPromisedAnswer(UInt32(4), ops))
        builder = RPC.build_call(UInt32(9), target, UInt64(0x1122), UInt16(3), (p, l) -> nothing)
        io = IOBuffer()
        Capnp.writeMessageToStream(builder, io)
        parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(take!(io))))
        pa = parsed.call.target.promised_answer
        @test pa.question_id == UInt32(4)
        @test length(pa.transform) == 3
        @test pa.transform[1].kind == RPC.PromisedAnswerOpType.GET_POINTER_FIELD
        @test pa.transform[1].get_pointer_field == UInt16(1)
        @test pa.transform[2].kind == RPC.PromisedAnswerOpType.NOOP
        @test pa.transform[3].get_pointer_field == UInt16(3)

        # An empty transform stays empty rather than becoming a bogus op
        empty_target = RPC.ParsedMessageTarget(RPC.MessageTargetType.PROMISED_ANSWER, nothing, RPC.ParsedPromisedAnswer(UInt32(4), RPC.PromisedAnswerOp[]))
        empty_builder = RPC.build_call(UInt32(9), empty_target, UInt64(0x1122), UInt16(3), (p, l) -> nothing)
        io2 = IOBuffer()
        Capnp.writeMessageToStream(empty_builder, io2)
        empty_parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(take!(io2))))
        @test isempty(empty_parsed.call.target.promised_answer.transform)
    end

    @testset "ParsedCapDescriptor keyword constructor" begin
        desc = RPC.ParsedCapDescriptor(RPC.CapDescriptorType.SENDER_HOSTED, sender_hosted = RPC.ExportId(4))
        @test desc.kind == RPC.CapDescriptorType.SENDER_HOSTED
        @test desc.sender_hosted == RPC.ExportId(4)
        @test desc.sender_promise === nothing
        @test desc.receiver_hosted === nothing
        @test desc.receiver_answer === nothing
    end

    @testset "Return exception precedence" begin
        # A result already set on the call context must not mask a later exception,
        # whatever its shape.
        for result in (42.0, RPC.ExportId(7))
            bytes = RPC.build_return_message(UInt32(31), result; has_exception = true, exception_reason = "boom")
            parsed = RPC.parse_rpc_message(Capnp.MessageReader(IOBuffer(bytes)))
            @test parsed.return_msg.kind == RPC.ReturnType.EXCEPTION
            @test parsed.return_msg.exception_reason == "boom"
        end
    end

    @testset "build_resolve_exception" begin
        # Returns raw bytes for transmission
        bytes = RPC.build_resolve_exception(UInt32(42), "Test error", RPC.ExceptionType.FAILED)
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
    end

    @testset "build_save_call" begin
        # Test building save call message - returns raw bytes
        bytes = RPC.build_save_call(UInt32(1), UInt32(10))
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
    end

    @testset "build_restore_call" begin
        # Test building restore call message - returns raw bytes
        sturdy_ref = RPC.DefaultSturdyRef("test-host", "test-object")
        sturdy_ref_data = RPC.serialize_sturdy_ref(sturdy_ref)
        bytes = RPC.build_restore_call(UInt32(1), UInt32(0), sturdy_ref_data)
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
    end
end
