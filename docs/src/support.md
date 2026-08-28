# Supported functionality

## Serialization

- Cap'n Proto stream framing and multiple segments
- Structs, primitive fields, lists, text, and capability pointers
- Default-value XOR handling
- Packed encoding, including zero-word and literal-word run optimization
- Generic schema metadata and Julia code generation
- Preallocated buffer readers and builders

## Bounded reads

Readers enforce message-size, segment-count, traversal-word, and nesting limits
on untrusted input, defaulting to 8 Mi words and 64 levels of nesting as the
reference implementation does. Malformed messages raise `InvalidMessageError`
rather than aborting or allocating without bound.

## RPC

- Typed bootstrap, generated client calls, and generated server dispatch
- Promise pipelining and promised-answer transforms
- Reference equality for capabilities received from the same peer: two
  references to one import compare equal, and hash alike
- TCP, Unix-domain, and IO-backed transports, plus TLS/mTLS when Reseau.jl is
  loaded

Capnp.jl targets the two-party network type. On that network, RPC levels 1 and
2 are the complete target: `rpc.capnp` states that level 3 is irrelevant for
two-party implementations, and level 4 reduces to reference equality between
capabilities received from the same peer.

## Out of scope

- RPC level 3, three-party handoff, and any vat network protocol beyond the
  two-party type

## Experimental or incomplete

- Complete handling of every RPC message variant
- Two-word far-pointer landing-pad generation, which is validated on read but
  not produced by the writer
- End-to-end interoperability coverage across supported Cap'n Proto versions
- Benchmarks, tracked performance baselines, and structured tracing

The package remains pre-1.0, so generated APIs may still change.
