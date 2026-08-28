```@raw html
---
layout: home

hero:
  name: Capnp.jl
  text: Cap'n Proto for Julia
  tagline: High-performance data serialization and RPC system.
  actions:
    - theme: brand
      text: Get Started
      link: ./support/
    - theme: alt
      text: GitHub Repository
      link: https://github.com/s-celles/Capnp.jl

features:
  - icon: 🚀
    title: Fast Serialization
    details: Zero-copy data serialization with robust performance.
  - icon: 🔄
    title: RPC Support
    details: Experimental and evolving support for Cap'n Proto RPC.
  - icon: 🛡️
    title: Julia Native
    details: Native Julia compiler plugin (`capnpc-jl`) for generating schema types.
---
```

# Capnp.jl

Capnp.jl implements [Cap'n Proto](https://capnproto.org/) serialization and code generation in pure Julia. 

Cap'n Proto is an insanely fast data interchange format and capability-based RPC system. Think JSON, except binary. Or think Protocol Buffers, except faster. In fact, in benchmarks, Cap’n Proto is infinity times faster than Protocol Buffers.

This package provides:
- A native **code generator plugin** (`capnpc-jl`) that compiles `.capnp` schemas into Julia code.
- **Zero-copy deserialization** allowing you to read messages directly from memory mappings.
- Early, experimental support for **Cap'n Proto RPC**.

```@contents
Pages = ["support.md", "api.md", "rpc.md", "rpc-functions.md"]
Depth = 2
```

## Installation

Capnp.jl requires Julia 1.10 or newer. Schema generation also requires the official `capnp` compiler executable to be installed on your system.

```julia
using Pkg
Pkg.add("Capnp")
```

## Basic message workflow

First, generate the Julia code from your schema using the repository's `capnpc-jl` plugin:

```sh
capnpc -o./capnpc-jl schema.capnp
```

Then, include the generated file in your Julia code, construct a message, and write it to an IO stream:

```julia
using Capnp
include("schema.capnp.jl")

message = Capnp.AllocMessageBuilder()
# Initialize and populate the generated root type here.
Capnp.writeMessageToStream(message, stdout)
```

!!! warning
    The reader bounds message framing, checks every pointer access, and enforces traversal-word and nesting budgets. The RPC layer, however, has not yet been through the performance, observability, and release-readiness work tracked in the roadmap; treat it as experimental.
