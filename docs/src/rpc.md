# Experimental RPC types

Bootstrap, generated calls, promise pipelining, and reference equality for
capabilities from one peer work end to end, covering RPC levels 1 and 2 on the
two-party network. The layer is still pre-production all the same: some message
variants, and the performance and tracing work, remain. See
[Supported functionality](@ref) before relying on it.

```@autodocs
Modules = [Capnp.RPC]
Public = true
Private = false
Order = [:module, :constant, :type]
```

```@docs
Capnp.RPC.MessageType
Capnp.RPC.ReturnType
Capnp.RPC.MessageTargetType
Capnp.RPC.SendResultsToType
Capnp.RPC.ResolveType
Capnp.RPC.CapDescriptorType
Capnp.RPC.CapDescriptorKind
Capnp.RPC.PromisedAnswerOpType
```
