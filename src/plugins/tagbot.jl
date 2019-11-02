"""
    TagBot(; destination="TagBot.yml", gpgsign=false)

Adds GitHub release support via [TagBot](https://github.com/JuliaRegistries/TagBot).

## Keyword Arguments
- `destination::AbstractString`: Destination of the worflow file,
  relative to `.github/workflows`.
- `gpgsign::Bool`: Whether or not to enable GPG signing of tags.
"""
@with_kw_noshow struct TagBot <: BasicPlugin
    destination::String = "TagBot.yml"
    gpgsign::Bool = false
end

source(::TagBot) = default_file("github", "workflows", "TagBot.yml")
destination(p::TagBot) = joinpath(".github", "workflows", p.destination)
tags(::TagBot) = "<<", ">>"
view(p::TagBot, ::Template, ::AbstractString) = Dict("HAS_GPG" => p.gpgsign)
