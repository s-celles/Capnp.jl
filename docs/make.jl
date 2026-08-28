using Capnp
using Documenter
using DocumenterLandingPage

DocMeta.setdocmeta!(Capnp, :DocTestSetup, :(using Capnp); recursive = true)

const DOC_URL = "https://s-celles.github.io/Capnp.jl/dev"

pages = ["Home" => "index.md", "Supported functionality" => "support.md", "API" => ["Serialization" => "api.md", "RPC types" => "rpc.md", "RPC functions" => "rpc-functions.md"]]

makedocs(
    modules = [Capnp, Capnp.RPC],
    sitename = "Capnp.jl",
    format = Documenter.HTML(canonical = "https://s-celles.github.io/Capnp.jl", edit_link = "main", prettyurls = get(ENV, "CI", "false") == "true"),
    plugins = [LandingPage()],
    pages = pages,
    checkdocs = :exports,
)

# Generate llms.txt and llms-full.txt (https://llmstxt.org) into the build
# directory, so they are served at the root of the docs site.

# Flatten the `pages` tree above into (title, source file) pairs, so the link
# list below never drifts from the actual navigation. That vector mixes leaves
# and sections, so its element type is `Pair{String, Any}`: dispatch on the
# value rather than on the type parameter.
flatten_pages(p::Pair) = flatten_pages(p.first, p.second)
flatten_pages(title, file::AbstractString) = [title => file]
flatten_pages(_, subpages::AbstractVector) = reduce(vcat, flatten_pages.(subpages))

const flat_pages = reduce(vcat, flatten_pages.(pages))

const llms_header = """
# Capnp.jl

> Cap'n Proto data serialization and RPC for Julia: zero-copy reads straight out of \
message buffers, a native `capnpc-jl` compiler plugin that turns `.capnp` schemas into \
Julia code, and experimental support for the Cap'n Proto RPC protocol.
"""

page_url(file) = file == "index.md" ? "$DOC_URL/" : "$DOC_URL/$(replace(file, r"\.md$" => ""))/"

llms = llms_header * "\n## Documentation\n" * join(["- [$title]($(page_url(file)))" for (title, file) in flat_pages], "\n") * "\n\n## Other\n- [Source code](https://github.com/s-celles/Capnp.jl)\n"

# The "full" variant inlines the markdown source of every page, minus the
# blocks that carry layout rather than content (the VitePress hero header, the
# generated tables of contents). `@docs` blocks are kept as-is: they name the
# exported symbols, even though the docstrings themselves are not expanded.
strip_layout(md) = replace(md, r"^```@(?:raw html|contents|index)\b.*?^```\n"ms => "")

llms_full = llms_header * "\n" * join(["\n---\n\n<!-- $file -->\n\n" * strip_layout(read(joinpath(@__DIR__, "src", file), String)) for (_, file) in flat_pages], "\n")

write(joinpath(@__DIR__, "build", "llms.txt"), llms)
write(joinpath(@__DIR__, "build", "llms-full.txt"), llms_full)

deploydocs(repo = "github.com/s-celles/Capnp.jl.git", devbranch = "main")
