"""
    TagBot(; destination="TagBot.yml", registry=nothing, dispatch=false)

Adds GitHub release support via [TagBot](https://github.com/JuliaRegistries/TagBot).

## Keyword Arguments
- `destination::AbstractString`: Destination of the worflow file,
  relative to `.github/workflows`.
- `registry::Union{AbstractString, Nothing}`: Custom registry, in the format `owner/repo`.
- `dispatch::Bool`: Whether or not to enable the `dispatch` option.
"""
@with_kw_noshow struct TagBot <: BasicPlugin
    destination::String = "TagBot.yml"
    registry::Union{String, Nothing} = nothing
    dispatch::Bool = false
end

source(::TagBot) = default_file("github", "workflows", "TagBot.yml")
destination(p::TagBot) = joinpath(".github", "workflows", p.destination)
tags(::TagBot) = "<<", ">>"

view(p::TagBot, ::Template, ::AbstractString) = Dict(
    "HAS_DISPATCH" => p.dispatch,
    "REGISTRY" => p.registry,
)
