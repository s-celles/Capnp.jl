# Capnp.jl Roadmap

This roadmap prioritizes a small, dependable serialization core and an optional
secure RPC stack. The base package will continue to depend only on Julia's
`Sockets` standard library for TCP and Unix-domain sockets. TLS, mTLS, deadline-
aware networking, and trim-safe deployment will be provided through a package
extension backed by [Reseau.jl](https://github.com/JuliaServices/Reseau.jl).

The intended differentiator is:

> Cap'n Proto RPC with optional mTLS, deployable as a trim-safe standalone Julia
> binary without adding TLS or OpenSSL to the base Capnp.jl dependency closure.

Calling the result a fully static binary should remain conditional on proving
the native-library story on each platform. Reseau currently uses `OpenSSL_jll`,
so a trim-safe executable may still need to bundle shared artifacts.

## Design principles

- Keep `Sockets` as the default and only mandatory network dependency.
- Add Reseau as a weak dependency; loading Capnp.jl alone must not load Reseau,
  NetworkOptions, or OpenSSL artifacts.
- Keep `RPC.connect` and `RPC.listen` as the stable user-facing API. Selecting
  TLS must be configuration, not a requirement for users to call or expose
  `Reseau.TCP`/`Reseau.TLS` objects in application APIs.
- Keep concrete transports available as an advanced escape hatch, including an
  already-connected IO-compatible stream for embedding and package extensions.
- Make security limits part of the transport and reader contracts, not optional
  advice in application code.
- Complete plain Cap'n Proto RPC correctness before presenting TLS as production
  ready. Encryption must not hide an incomplete protocol implementation.
- Test behavior against the reference C++ implementation, not only Julia peers.
- Treat `--trim=safe` as a continuously tested constraint on public APIs and
  generated code.
- Avoid parallel compatibility bots: Dependabot is the selected mechanism for
  Julia and GitHub Actions dependencies.

## Current baseline

The `main` branch establishes the following baseline:

- Julia 1.10 is the minimum supported version.
- CI covers Julia 1.10 and the latest stable Julia on Linux, macOS, and Windows.
- Aqua, formatting, code coverage, Dependabot, TagBot, and Documenter are wired.
- Stream framing enforces message-size and segment-count limits and rejects
  truncation and non-zero framing padding.
- Readers enforce traversal-word budgets and nesting limits, defaulting to
  8 Mi words and 64 levels as the reference implementation does.
- Core pointer reads and writes perform segment and byte-range checks.
- RPC TCP, Unix, and mock transports propagate framing limits.
- A generated Julia client can bootstrap and call a generated Julia server.
- Basic Cap'n Proto C++ serialization interoperability is tested.

This is a safety and maintenance baseline, not yet a complete RPC release.

## Documentation accuracy

An audit found user-facing claims that no longer matched the code: features
shipped, but the package still advertised them as absent. Corrected across
README.md, `docs/src/`, `example/`, and KNOWN_ISSUES.md.

- [x] Stop claiming traversal and nesting budgets are unenforced. Enforcement
      lives in `_decrement_traversal_limit!` and `_descend_nesting_limit`
      (`src/runtime_lib.jl:75-83`) and is reached from every struct, list, and
      text read. This was the most harmful stale claim: it warned users away
      from a guarantee the package actually provides.
- [x] Stop claiming generated RPC calls are unimplemented. `src/generator.jl`
      emits real client calls into `Capnp.RPC.call`, and `test/rpc/calculator.jl`
      exercises a full Julia client to Julia server round trip.
- [x] Restate packed zero/literal run optimization as shipped, and two-word
      landing-pad generation as the remaining wire-format gap.
- [x] Note that CI exercises interoperability against Cap'n Proto C++ 1.3.0,
      alongside the v0.9.2 observation recorded in KNOWN_ISSUES.md.

When a milestone item is checked, the claim it supports should be updated in
README.md and `docs/src/support.md` in the same change.

## Milestone 1 — Stable transport boundary

Goal: make the RPC engine independent of the concrete full-duplex byte stream.

- [x] Complete the minimal transport contract. Exact message reads, complete
      serialized writes, flush semantics, peer shutdown, and idempotent close
      are now specified; half-close, deadlines, and cancellation remain.
- [x] Keep `TcpTransport` and `UnixTransport` implemented with `Sockets`.
- [x] Disable Nagle's algorithm (`TCP_NODELAY`) on TCP transports, listeners,
      and accepted sockets by default, with `tcp_nodelay` opt-out on
      `ConnectionOptions` and `ServerOptions`.
- [x] Introduce a reusable IO-backed transport where it reduces
      duplication without weakening the explicit TCP and Unix APIs.
- [x] Make connection ownership explicit. Connections own and close their
      transport by default; callers adapting an externally-owned stream can opt
      out.
- [x] Apply or remove currently inert options. In particular,
      `send_buffer_size`, `receive_buffer_size`, `connection_timeout`,
      `traversal_limit`, and `nesting_limit` are validated or stored today but
      are not all enforced.
- [x] Specify how transport deadline errors map to Capnp RPC errors and promise
      rejection.
- [x] Add backpressure and bounded outbound/inbound RPC queues.
- [x] Test partial reads, partial writes, simultaneous close, peer reset,
      cancellation during IO, and repeated close.

Acceptance criteria:

- The same transport conformance suite passes for TCP, Unix, mock, and the future
  Reseau TLS transport.
- The default dependency graph remains limited to standard libraries.
- No transport-specific branch is required in the RPC protocol engine.

Stable façade policy:

- Normal users call `RPC.connect(...)`, `RPC.listen(...)`, `bootstrap(...)`, and
  generated methods. Plain TCP remains the default when given a host and port.
- Loading Reseau will add TLS/mTLS configuration accepted by that same façade;
  it will not replace the default methods or make Reseau types part of generated
  client/server signatures.
- `TcpTransport`, `UnixTransport`, and `IOTransport` remain documented advanced
  APIs for custom connection setup, tests, proxies, and integrations.

## Milestone 2 — Complete the plain RPC path

Goal: establish a correct end-to-end RPC implementation over `Sockets` before
adding TLS.

- [x] Replace the placeholder `bootstrap` implementation with a typed bootstrap
      capability returned from an actual `Bootstrap`/`Return` exchange.
- [x] Implement generated client calls instead of emitting the current
      "not implemented" path.
- [x] Run and supervise the client receive loop. The loop is now started by the
      connection façade and rejects pending questions on failure; cancellation,
      bounded supervision, and exhaustive exactly-once tests remain.
- [x] Complete `Return`, `Finish`, `Release`, `Resolve`, exception, cancellation,
      and disconnect handling.
- [x] Implement promise pipelining and promised-answer transforms with explicit
      lifecycle tests.
- [x] Remove calculator-specific assumptions from server dispatch and generate
      interface/method dispatch tables for arbitrary schemas.
- [x] Finish capability-table reference counting, release accounting, and cleanup
      after failed calls.
- [x] Define reconnection semantics. Default to failing in-flight questions
      rather than silently replaying non-idempotent calls.
- [x] Complete persistent capability ownership and restoration semantics; owner
      extraction is currently a placeholder.
- [x] Replace `throw("...")` and assertions reachable from wire data with typed
      exceptions such as `InvalidMessageError` or RPC protocol errors.
- [x] Define and test capability equality for the two-party network. Two
      references to one import on one connection now compare equal through an
      explicit `==`/`isequal`/`hash` on `RemoteCapability`, keyed on the import
      ID and the connection, with the reference count excluded. The four
      get-or-create sites are replaced by `import_capability!`, which holds the
      connection lock across the lookup and the insert; previously each site
      took the lock twice, so two receive paths racing on one import could each
      register a separate object. This is the part of RPC level 4 a two-party
      implementation can reach; cross-vat `Join` is out of scope along with
      level 3, below.

Acceptance criteria:

- A generated Julia client can bootstrap and call a generated Julia server.
- The same Julia client can bootstrap and call a reference Cap'n Proto C++
  server over plain TCP.
- Disconnects, malformed responses, remote exceptions, `Finish`, and capability
  release leave no unresolved promises or leaked table entries.

## Milestone 3 — Optional Reseau extension

Goal: add TLS and mTLS without changing the base installation footprint.

Planned package structure:

```toml
[weakdeps]
Reseau = "802f3686-a58f-41ce-bb0c-3c43c75bba36"

[extensions]
CapnpReseauExt = "Reseau"

[compat]
Reseau = "1"
```

The implementation will live in `ext/CapnpReseauExt.jl`. It should extend a
Capnp-owned endpoint/configuration type and adapt the connected Reseau stream
through the transport boundary. Application-facing signatures and generated
code should not mention `Reseau.TCP` or `Reseau.TLS`; direct construction of an
`IOTransport` from a Reseau stream remains an advanced escape hatch.

- [x] Implement a Reseau-backed transport over `Reseau.TLS` with the same
      framing limits as the base transports.
- [x] Add client connection methods for hostname-aware TLS dialing, CA roots,
      hostname verification, SNI, optional ALPN, client certificates, and keys.
- [x] Add TLS listener/server methods with certificate/key configuration and
      optional or required verified client authentication.
- [x] Map Reseau deadline and TLS errors into stable Capnp transport/RPC errors
      while retaining the original exception as diagnostic context.
- [x] Ensure read, write, handshake, and accept deadlines can be configured and
      cancelled independently.
- [x] Redact private keys, tokens, and sensitive certificate material from
      logging and exception display.
- [x] Add extension-specific precompile workloads without introducing runtime
      code generation.
- [x] Document explicit loading: base users get `Sockets`; users who install and
      load Reseau activate secure transports.

Acceptance criteria:

- `using Capnp` does not install or load Reseau/OpenSSL.
- `using Capnp, Reseau` activates the extension on Julia 1.10+.
- Plain TCP and Unix APIs retain their current behavior and performance envelope.
- TLS 1.2 and TLS 1.3, server verification, and mTLS are exercised in CI.

## Milestone 4 — C++/OpenSSL interoperability through stunnel

Goal: validate Julia's secure client against an independent TLS stack and the
reference Cap'n Proto RPC implementation.

Primary topology:

```text
Julia generated client
  -> Capnp.jl RPC
  -> Reseau.TLS.connect (client certificate + server verification)
  -> mTLS / OpenSSL
  -> stunnel server
  -> loopback plaintext TCP
  -> reference capnp C++ RPC server
```

- [x] Build a minimal C++ bootstrap service from a checked-in `.capnp` schema.
- [x] Start the C++ server only on an ephemeral loopback port.
- [x] Put stunnel in front of it with a generated test CA, server certificate,
      and required client-certificate verification.
- [x] Connect with `Reseau.TLS.connect`, perform a typed bootstrap and RPC call,
      validate the result, then complete `Finish`/release and clean shutdown.
- [x] Verify certificate chain, hostname/SAN, SNI, validity dates, EKU, and client
      certificate authentication.
- [x] Add negative tests for unknown CA, hostname mismatch, absent client cert,
      wrong client CA, expired/not-yet-valid cert, truncated TLS records, and
      handshake timeout.
- [ ] Capture stunnel and C++ logs as CI artifacts on failure, without storing
      private-key contents.
- [ ] Add the reverse topology later: C++ client behind stunnel against a Julia
      Reseau TLS listener.
- [ ] Test at least Cap'n Proto C++ 1.3 and the latest supported release; expand
      the version matrix when compatibility policy is documented.

This test should first run on Linux, where stunnel packaging is predictable. Add
macOS and Windows coverage after the protocol test is stable.

## Milestone 5 — Trim-safe and standalone deployment

Goal: prove that generated RPC applications, including the optional TLS path,
can be compiled under Julia's trimming constraints.

- [x] Add a minimal plain-TCP RPC application compiled with `--trim=safe`.
- [x] Add a second application that loads `CapnpReseauExt`, performs a verified
      TLS or mTLS call, and exits cleanly.
- [x] Eliminate runtime `eval`, dynamic method creation, reflective dispatch,
      and avoidable `Any` from paths reachable by compiled applications.
- [ ] Make generated schema and RPC code inference-friendly and precompilable.
- [ ] Verify certificate and OpenSSL artifacts are bundled correctly on Linux,
      macOS, and Windows.
- [ ] Record binary size, cold start, first connection, handshake, and first-call
      latency as non-blocking metrics before setting regression budgets.
- [ ] Determine and document whether each target is fully static or a standalone
      bundle containing shared native libraries.

Acceptance criteria:

- CI builds and executes the trim-safe plain and TLS smoke applications.
- The TLS application completes the stunnel/C++ interoperability call without a
  full Julia development environment present.
- Marketing uses "fully static" only on platforms where the produced artifact
  has been inspected and meets that definition.

## Milestone 6 — Hostile-input and resource safety

Goal: move untrusted-message handling from experimental to explicitly bounded.

- [x] Enforce traversal-word budgets across pointer following and repeated reads.
- [x] Enforce nesting limits for structs, lists, far pointers, and RPC payloads.
- [x] Bound capability-table sizes, outstanding questions/answers, pipeline
      transforms, queued messages, and exception/reason text.
- [x] Detect cycles and amplification patterns without quadratic work (handled by traversal limits).
- [x] Validate struct/list extents when pointers are resolved, not only when a
      later scalar field is read.
- [x] Validate all reserved pointer bits and replace wire-facing assertions with
      typed malformed-message errors.
- [x] Make framing writes explicitly little-endian as reads already are.
- [x] Add property tests and coverage-guided fuzzing for framing, packed streams,
      pointers, lists, text, capability descriptors, and RPC messages.
- [x] Seed the corpus with truncations, oversized declarations, invalid UTF-8,
      backward pointers, single/double-far pointers, and deep/cyclic graphs.
- [ ] Run sanitizers in the C++ interoperability fixtures where practical.

Acceptance criteria:

- Every public reader entry point has documented size, traversal, and nesting
  behavior.
- Malformed input produces typed errors without process crashes, unbounded
  allocation, hangs, or assertion failures.

## Milestone 7 — Wire format and generator completeness

- [x] Strictly validate both far-pointer landing-pad forms on read, including
      the second word of a double-far landing pad.
- [ ] Emit far pointers at all. The writer is single-segment: `current_segment`
      is set to 1 at construction and never reassigned, and `alloc` grows the
      one segment by doubling it. `write_far_pointer` therefore has no callers
      and is dead code, so neither landing-pad form is ever produced. Two-word
      landing pads cannot be implemented in isolation; they only arise once the
      builder allocates across segments. The prerequisite is multi-segment
      writing in `AllocMessageBuilder`, which also touches
      `writeMessageToStream` (it treats `current_segment` as "the last one").
      Single-segment output is valid Cap'n Proto, so this is an allocation
      concern, not a correctness or interoperability one: measure before
      committing to it (see Milestone 8).
- [x] Complete packed encoding zero-word and literal-word run optimizations and
      test byte-for-byte compatibility with `capnp`.
- [ ] Improve segment allocation to avoid the current wasteful growth strategy
      and unnecessary landing pads. Unchecked after audit: `alloc` still doubles
      the single segment with a full `resize!` and copy, and no landing pads are
      emitted to be unnecessary in the first place. Shares the multi-segment
      prerequisite with the far-pointer item above.
- [x] Complete schema-tree cases that still throw `TODO`, including complex
      values, brands, groups, and nested/generic constructs.
- [x] Respect declaration/code order where required and harden namespace/import
      handling across multiple generated schema files.
- [x] Finish lists of pointers/structs and less-common list element forms.
- [x] Define generated API stability rules before 1.0 and minimize method-name
      collisions by encouraging module-scoped generated schemas.
- [ ] Re-enable or replace the currently excluded `copy_schema.jl` work.
      Unchecked after audit: no `copy_schema.jl` exists anywhere in the tree,
      and the placeholder it left behind was an empty
      `@testset "Code Generator Request Copy"` in `test/runtests.jl`, since
      removed. The standalone C++ interoperability tests are wired in.
- [x] Add golden-generation tests so generator changes produce reviewable diffs.
      `test/golden_tests.jl` diffs four schemas against `test/goldens/`, with
      `UPDATE_GOLDENS=true` to re-record them. The references are tracked
      despite the blanket `*.capnp.jl` ignore rule; without that exception they
      were absent from every clone and the suite failed on a fresh checkout.

## Milestone 8 — Performance, observability, and release readiness

- [ ] Replace permissive timing assertions with a dedicated benchmark suite and
      tracked baselines for framing, pointer access, packed IO, RPC, and TLS.
- [ ] Measure allocations on real message/RPC workloads, including fragmented
      transport reads and multiple segments.
- [ ] Add opt-in structured tracing for connection, question, answer, capability,
      and handshake lifecycle events.
- [ ] Keep secrets and application payloads out of default logs.
- [ ] Document supported Cap'n Proto C++ versions, Julia versions, operating
      systems, TLS versions, and extension compatibility.
- [ ] Add end-user guides for plain TCP, Unix sockets, TLS, mTLS, stunnel, and
      trim-safe deployment.
- [ ] Establish deprecation and security-response policies for generated APIs and
      wire-facing vulnerabilities.
- [ ] Require green cross-platform CI, strict docs, Aqua, interop, fuzz smoke,
      and trim-safe smoke tests before a production-RPC claim.

## Suggested delivery order

1. Stabilize the transport contract and enforce all existing options.
2. Complete plain RPC bootstrap, calls, returns, lifecycle, and C++ interop.
3. Add the weak Reseau extension and its TLS/mTLS conformance tests.
4. Add the Julia -> Reseau TLS -> stunnel -> C++ end-to-end test.
5. Prove trim-safe standalone deployment and document native artifact behavior.
6. Finish hostile-input budgets, fuzzing, wire completeness, and performance
   gates before declaring RPC production ready.

## Explicit non-goals

- Replacing `Sockets` with Reseau in the base package.
- Making TLS mandatory for serialization-only users.
- Implementing a second TLS stack inside Capnp.jl.
- Claiming full Cap'n Proto RPC compatibility from Julia-only tests.
- Claiming a fully static mTLS binary before inspecting its native dependencies.
- Implementing a vat network protocol beyond the two-party type, and therefore
  RPC level 3. Level 3 exists so that vat B can form a direct connection to
  vat C when vat A hands it a reference; Capnp.jl is two-party by construction,
  since its transports are TCP, Unix sockets, and adapted IO streams, all point
  to point. `rpc.capnp` is explicit that this is the right target: "New
  implementations of Cap'n Proto should start out targeting the simplistic
  two-party network type as defined in `rpc-twoparty.capnp`. With this network
  type, level 3 is irrelevant and levels 2 and 4 are much easier than usual to
  implement." Levels 1 and 2 on the two-party network are therefore the
  complete target for this package, not a partial one.

## References

- [Reseau.jl](https://github.com/JuliaServices/Reseau.jl)
- [Reseau TLS documentation](https://juliaservices.github.io/Reseau.jl/stable/tls/)
- [Cap'n Proto RPC protocol](https://capnproto.org/rpc.html)
- [stunnel](https://www.stunnel.org/)
