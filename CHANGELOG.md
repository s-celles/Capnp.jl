# Changelog

All notable changes to Capnp.jl are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Experimental Cap'n Proto RPC client, server, promise, transport, and persistence infrastructure.
- Default-value, packed-encoding, generic-schema, and preallocated-buffer support.
- Cross-platform CI, Aqua quality checks, code coverage, Dependabot, and Documenter documentation.
- Strict stream-framing limits and malformed-message regression tests.
- `TCP_NODELAY` support: TCP transports, connections, and listeners now disable Nagle's algorithm by default (`ConnectionOptions(tcp_nodelay = ...)`, `ServerOptions(tcp_nodelay = ...)`, `TcpTransport(...; nodelay = ...)`, and the `RPC.set_tcp_nodelay!` helper).
- `Text` results for RPC methods: `RPC.set_result!(context, ::AbstractString)` now returns a results struct with a `Text` field in pointer slot 0, built by the new `RPC.build_text_return`. Previously only `Float64` and capability results could be returned.
- Results structs of any schema-declared shape: `RPC.set_results!(context, build; data_word_count, pointer_count)` hands the method a `Capnp.StructPointer` to fill in, mirroring the `params_builder` a client passes to `RPC.call`. `RPC.write_capability!` places a capability in one of its pointer slots, exporting it and adding the matching capability-table entry in one step. Backed by the new `RPC.ResultsBuilder` and `RPC.build_results_return`.
- `PromisedAnswer.transform` is now written and parsed, so a pipelined call can name the pointer slot it wants. Previously the transform list was dropped on send and ignored on receive.
- `ParsedCapDescriptor(kind; sender_hosted = ...)` keyword constructor, which `add_capability_to_message!` already assumed existed.
- Scalar results keep their declared type on the wire: `Bool`, the signed and unsigned integer widths, `Float32` and `Float64` are written as themselves instead of all being coerced to `Float64` (`RPC.SCALAR_RESULT_TYPES`).

### Fixed

- Hangs during RPC message resolution due to invalid parsing of `Return` messages.
- Silent failure during `Finish` message dispatch for RPC calls.
- `InvalidCapabilityException` during `bootstrap` extraction from `Return` messages.
- `build_return_message` dropped a pending exception when a result had already been set on the call context; the exception now takes precedence over any result.
- `MessageTarget.importedCap` and the `CapDescriptor` export/import ids were written 28 bytes past their field, because `write_bits` takes a byte offset while the call sites passed a bit offset. Every call to an imported capability therefore went out with `importedCap = 0`, which is the export id the bootstrap capability happens to get, so calls silently landed on the bootstrap instead of failing. Servers exposing more than one capability were unusable.
- Pipelined calls resolved `getPointerField(n)` to the n-th exported capability rather than the capability in pointer slot `n`, which is only the same thing when every pointer slot holds a capability. Answers now record which slot holds which capability; answers built through paths that do not track slots keep the previous behaviour.
- Integer results above 2^53 were silently rounded, because every numeric result was coerced to `Float64`. They are now exact.
- `set_result!` rejects a result it cannot put on the wire instead of silently sending `0.0`. Validation happens in `set_result!`, inside the server's error handling, so the caller gets an exception `Return` rather than a dropped connection.
- A Call whose target cannot be resolved is now refused with a reason naming what was missing, instead of being answered by a substitute capability. Three separate substitutions are gone: `parse_message_target` no longer invents `importedCap = 0` for a Call with no target, `handle_call_message!` no longer falls back to export id 1 when a promised answer cannot be resolved, and export ids now start at 1 so that a zeroed or missing id on the wire cannot name a real capability.

### Changed

- **New package UUID.** This fork now has its own identity, `b5c95173-5a77-49d3-b7f3-d0bfa1b96fb4`, instead of reusing `4a176cb5-e787-4417-92d8-5e07a66a639e`, which the General registry assigns to the upstream `OndrejSlamecka/Capnp.jl`. Environments that depended on this fork must update the UUID in their `Project.toml`.
- `Project.toml` lists Sébastien Celles first, as the author and maintainer of this version. Ondřej Slámečka remains credited as the original author, and is explicitly not a maintainer of this fork; see `CONTRIBUTORS.md`.
- **Breaking for unresolvable call targets.** A Call naming a capability the peer cannot resolve now comes back as an exception `Return` rather than being served by the bootstrap or by export id 1. Callers that relied on a targetless or mis-addressed Call reaching the bootstrap must name it explicitly. Export ids also start at 1 rather than 0, so the bootstrap capability is import id 1.
- **Breaking for integer results.** A non-`Float64` numeric result now goes on the wire as its own type rather than as a `Float64`. A method answering a `-> (value :Float64)` field must pass a `Float64`: `set_result!(ctx, 30)` now sends an `Int64`, where it used to send `30.0`. `UInt32` is unaffected and still means "return this capability", since `ExportId` is an alias for `UInt32`; use `set_results!` to return a `UInt32` field.
- Replaced multiple unstructured string throws with typed `InvalidMessageError`.
- Removed currently unused RPC server/connection options (e.g. `connection_timeout`, `send_buffer_size`) to clarify the working API.

### Changed

- Julia 1.10 is now the minimum supported version.
- The generated API uses Julia-style snake-case names while retaining deprecated compatibility wrappers.

### Security

- Message framing now rejects excessive segment counts, oversized messages, non-zero padding, and truncated segments.
- Core pointer reads and writes validate segment and byte ranges before accessing memory.
