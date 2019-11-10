"""
    CompatHelper(;
        file="$(contractuser(default_file("github", "workflows", "CompatHelper.yml")))",
        destination="CompatHelper.yml",
    )

Integrates your packages with [CompatHelper](https://github.com/bcbi/CompatHelper.jl) via GitHub Actions.

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the worflow file,
  relative to `.github/workflows`.
"""
@with_kw_noshow struct CompatHelper <: BasicPlugin
    file::String = default_file("github", "workflows", "CompatHelper.yml")
    destination::String = "CompatHelper.yml"
end

source(p::CompatHelper) = p.file
destination(p::CompatHelper) = joinpath(".github", "workflows", p.destination)
tags(::CompatHelper) = "<<", ">>"

function view(p::CompatHelper, t::Template, ::AbstractString)
    return Dict("VERSION" => format_version(max(v"1.2", t.julia)))
end
