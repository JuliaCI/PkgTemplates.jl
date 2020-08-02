"""
    TagBot(;
        file="$(contractuser(default_file("github", "workflows", "TagBot.yml")))",
        destination="TagBot.yml",
        cron="0 0 * * *",
        token=Secret("GITHUB_TOKEN"),
        ssh=Secret("DOCUMENTER_KEY"),
        ssh_password=nothing,
        changelog=nothing,
        changelog_ignore=nothing,
        gpg=nothing,
        gpg_password=nothing,
        registry=nothing,
        branches=nothing,
        dispatch=nothing,
        dispatch_delay=nothing,
    )

Adds GitHub release support via [TagBot](https://github.com/JuliaRegistries/TagBot).

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file, relative to `.github/workflows`.
- `cron::AbstractString`: Cron expression for the schedule interval.
- `token::Secret`: Name of the token secret to use.
- `ssh::Secret`: Name of the SSH private key secret to use.
- `ssh_password::Secret`: Name of the SSH key password secret to use.
- `changelog::AbstractString`: Custom changelog template.
- `changelog_ignore::Vector{<:AbstractString}`: Issue/pull request labels to ignore in the changelog.
- `gpg::Secret`: Name of the GPG private key secret to use.
- `gpg_password::Secret`: Name of the GPG private key password secret to use.
- `registry::AbstractString`: Custom registry, in the format `owner/repo`.
- `branches::Bool`: Whether not to enable the `branches` option.
- `dispatch::Bool`: Whether or not to enable the `dispatch` option.
- `dispatch_delay::Int`: Number of minutes to delay for dispatch events.
"""
@plugin struct TagBot <: FilePlugin
    file::String = default_file("github", "workflows", "TagBot.yml")
    destination::String = "TagBot.yml"
    cron::String = "0 0 * * *"
    token::Secret = Secret("GITHUB_TOKEN")
    ssh::Union{Secret, Nothing} = Secret("DOCUMENTER_KEY")
    ssh_password::Union{Secret, Nothing} = nothing
    changelog::Union{String, Nothing} = nothing
    changelog_ignore::Union{Vector{String}, Nothing} = nothing
    gpg::Union{Secret, Nothing} = nothing
    gpg_password::Union{Secret, Nothing} = nothing
    registry::Union{String, Nothing} = nothing
    branches::Union{Bool, Nothing} = nothing
    dispatch::Union{Bool, Nothing} = nothing
    dispatch_delay::Union{Int, Nothing} = nothing
end

source(p::TagBot) = p.file
destination(p::TagBot) = joinpath(".github", "workflows", p.destination)

function view(p::TagBot, ::Template, ::AbstractString)
    changelog = if p.changelog === nothing
        nothing
    else
        # This magic number aligns the text block just right.
        lines = map(line -> rstrip(repeat(' ', 12) * line), split(p.changelog, "\n"))
        "|\n" * join(lines, "\n")
    end
    ignore = p.changelog_ignore === nothing ? nothing : join(p.changelog_ignore, ", ")

    return Dict(
        "BRANCHES" => p.branches === nothing ? nothing : string(p.branches),
        "CHANGELOG" => changelog,
        "CHANGELOG_IGNORE" => ignore,
        "CRON" => p.cron,
        "DISPATCH" => p.dispatch === nothing ? nothing : string(p.dispatch),
        "DISPATCH_DELAY" => p.dispatch_delay,
        "GPG" => p.gpg,
        "GPG_PASSWORD" => p.gpg_password,
        "REGISTRY" => p.registry,
        "SSH" => p.ssh,
        "SSH_PASSWORD" => p.ssh_password,
        "TOKEN" => p.token,
    )
end
