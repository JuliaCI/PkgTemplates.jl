"""
    CompatHelper(;
        file="$(contractuser(default_file("github", "workflows", "CompatHelper.yml")))",
        destination="CompatHelper.yml",
        cron="0 0 * * *",
    )

Integrates your packages with [CompatHelper](https://github.com/bcbi/CompatHelper.jl) via GitHub Actions.

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
