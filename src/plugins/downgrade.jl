"""
    DowngradeDependencyTests(;
        file="$(contractuser(default_file("github", "workflows", "Downgrade.yml")))",
        destination="Downgrade.yml",
        skip=["Pkg", "TOML"],
        badge=false,
    )

Integrates your packages with [GitHub Actions](https://github.com/features/actions)
to test with minimum compatible dependency versions using
[julia-downgrade-compat-action](https://github.com/cjdoris/julia-downgrade-compat-action).

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file,
  relative to `.github/workflows`.
- `skip::Vector{String}`: Packages to skip when downgrading (e.g., stdlib packages).
- `badge::Bool`: Whether or not to display a status badge in the README.
"""
@plugin struct DowngradeDependencyTests <: FilePlugin
    file::String = default_file("github", "workflows", "Downgrade.yml")
    destination::String = "Downgrade.yml"
    skip::Vector{String} = ["Pkg", "TOML"]
    badge::Bool = false
end

source(p::DowngradeDependencyTests) = p.file
destination(p::DowngradeDependencyTests) = joinpath(".github", "workflows", p.destination)
tags(::DowngradeDependencyTests) = "<<", ">>"

badges(p::DowngradeDependencyTests) = p.badge ? Badge(
    "Downgrade",
    "https://github.com/{{{USER}}}/{{{PKG}}}.jl/actions/workflows/$(p.destination)/badge.svg?branch={{{BRANCH}}}",
    "https://github.com/{{{USER}}}/{{{PKG}}}.jl/actions/workflows/$(p.destination)?query=branch%3A{{{BRANCH}}}",
) : Badge[]

function view(p::DowngradeDependencyTests, t::Template, pkg::AbstractString)
    v = Dict(
        "PKG" => pkg,
        "USER" => t.user,
        "SKIP" => join(p.skip, ","),
        "HAS_SKIP" => !isempty(p.skip),
    )
    git = getplugin(t, Git)
    if git !== nothing
        v["BRANCH"] = git.branch
    end
    return v
end

needs_username(::DowngradeDependencyTests) = true
