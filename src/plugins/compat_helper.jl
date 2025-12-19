"""
    CompatHelper(;
        file="$(contractuser(default_file("github", "workflows", "CompatHelper.yml")))",
        destination="CompatHelper.yml",
        cron="0 0 * * *",
    )

Integrates your packages with [CompatHelper](https://github.com/bcbi/CompatHelper.jl) via GitHub Actions.

!!! note "Deprecated in favor of Dependabot"
    As of December 2025, [Dependabot supports Julia](https://github.blog/changelog/2025-12-16-dependabot-version-updates-now-support-julia/)
    and is now the recommended approach for keeping package dependencies up to date.
    The [`Dependabot`](@ref) plugin is included in the default template plugins.
    `CompatHelper` remains available for users who prefer it.

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file,
  relative to `.github/workflows`.
- `cron::AbstractString`: Cron expression for the schedule interval.
"""
@plugin struct CompatHelper <: FilePlugin
    file::String = default_file("github", "workflows", "CompatHelper.yml")
    destination::String = "CompatHelper.yml"
    cron::String = "0 0 * * *"
end

source(p::CompatHelper) = p.file
destination(p::CompatHelper) = joinpath(".github", "workflows", p.destination)
tags(::CompatHelper) = "<<", ">>"

view(p::CompatHelper, ::Template, ::AbstractString) = Dict("CRON" => p.cron)
