"""
    TagBot(;
        destination="TagBot.yml",
        gpgsign=false,
        registry=nothing,
        github_site=nothing,
        github_api=nothing,
    )

Adds GitHub release support via [TagBot](https://github.com/JuliaRegistries/TagBot).

## Keyword Arguments
- `destination::AbstractString`: Destination of the worflow file,
  relative to `.github/workflows`.
- `gpgsign::Bool`: Whether or not to enable GPG signing of tags.
- `registry::Union{AbstractString, Nothing}`: Custom registry, in the format `owner/repo`.
- `github_site::Union{AbstractString, Nothing}`: URL to a self-hosted GitHub instance.
- `github_api::Union{AbstractString, Nothing}`: URL to a self-hosted GitHub instance's API.

!!! note
    If you set `gpgsign`, you must add the `GPG_KEY` secret to your repository yourself.
"""
@with_kw_noshow struct TagBot <: BasicPlugin
    destination::String = "TagBot.yml"
    gpgsign::Bool = false
    registry::Union{String, Nothing} = nothing
    github_api::Union{String, Nothing} = nothing
    github_site::Union{String, Nothing} = nothing
end

source(::TagBot) = default_file("github", "workflows", "TagBot.yml")
destination(p::TagBot) = joinpath(".github", "workflows", p.destination)
tags(::TagBot) = "<<", ">>"

function view(p::TagBot, ::Template, ::AbstractString)
    return Dict(
        "GITHUB_API" => p.github_api,
        "GITHUB_SITE" => p.github_site,
        "HAS_GPG" => p.gpgsign,
        "REGISTRY" => p.registry,
    )
end
