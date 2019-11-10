const DOCUMENTER_DEP = PackageSpec(;
    name="Documenter",
    uuid="e30172f5-a6a5-5a46-863b-614d45cd2de4",
)

const DeployStyle = Union{TravisCI, GitHubActions, GitLabCI, Nothing}
const GitHubPagesStyle = Union{TravisCI, GitHubActions}

"""
    Documenter{T<:Union{TravisCI, GitLabCI, Nothing}}(;
        make_jl="$(contractuser(default_file("docs", "make.jl")))",
        index_md="$(contractuser(default_file("docs", "src", "index.md")))",
        assets=String[],
        canonical_url=make_canonical(T),
        makedocs_kwargs=Dict{Symbol, Any}(),
    )

Sets up documentation generation via [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
Documentation deployment depends on `T`, where `T` is some supported CI plugin,
or `Nothing` to only support local documentation builds.

## Supported Type Parameters
- `GitHubActions`: Deploys documentation to [GitHub Pages](https://pages.github.com)
  with the help of [`GitHubActions`](@ref).
- `TravisCI`: Deploys documentation to [GitHub Pages](https://pages.github.com)
  with the help of [`TravisCI`](@ref).
- `GitLabCI`: Deploys documentation to [GitLab Pages](https://pages.gitlab.com)
  with the help of [`GitLabCI`](@ref).
- `Nothing` (default): Does not set up documentation deployment.

## Keyword Arguments
- `make_jl::AbstractString`: Template file for `make.jl`.
- `index_md::AbstractString`: Template file for `index.md`.
- `assets::Vector{<:AbstractString}`: Extra assets for the generated site.
- `canonical_url::Union{Function, Nothing}`: A function to generate the site's canonical URL.
  The default value will compute GitHub Pages and GitLab Pages URLs
  for [`TravisCI`](@ref) and [`GitLabCI`](@ref), respectively.
  If set to `nothing`, no canonical URL is set.
- `makedocs_kwargs::Dict{Symbol}`: Extra keyword arguments to be inserted into `makedocs`.

!!! note
    If deploying documentation with Travis CI, don't forget to complete
    [the required configuration](https://juliadocs.github.io/Documenter.jl/stable/man/hosting/#SSH-Deploy-Keys-1).
"""
struct Documenter{T<:DeployStyle} <: Plugin
    assets::Vector{String}
    makedocs_kwargs::Dict{Symbol}
    canonical_url::Union{Function, Nothing}
    make_jl::String
    index_md::String

    # Can't use @with_kw_noshow due to some weird precompilation issues.
    function Documenter{T}(;
        assets::Vector{<:AbstractString}=String[],
        makedocs_kwargs::Dict{Symbol}=Dict{Symbol, Any}(),
        canonical_url::Union{Function, Nothing}=make_canonical(T),
        make_jl::AbstractString=default_file("docs", "make.jl"),
        index_md::AbstractString=default_file("docs", "src", "index.md"),
    ) where T <: DeployStyle
        return new(assets, makedocs_kwargs, canonical_url, make_jl, index_md)
    end
end

Documenter(; kwargs...) = Documenter{Nothing}(; kwargs...)

gitignore(::Documenter) = ["/docs/build/"]

badges(::Documenter) = Badge[]
badges(::Documenter{<:GitHubPagesStyle}) = [
    Badge(
        "Stable",
        "https://img.shields.io/badge/docs-stable-blue.svg",
        "https://{{{USER}}}.github.io/{{{PKG}}}.jl/stable",
    ),
    Badge(
        "Dev",
        "https://img.shields.io/badge/docs-dev-blue.svg",
        "https://{{{USER}}}.github.io/{{{PKG}}}.jl/dev",
    ),
]
badges(::Documenter{GitLabCI}) = Badge(
    "Dev",
    "https://img.shields.io/badge/docs-dev-blue.svg",
    "https://{{{USER}}}.gitlab.io/{{{PKG}}}.jl/dev",
)

view(p::Documenter, t::Template, pkg::AbstractString) = Dict(
    "ASSETS" => map(basename, p.assets),
    "AUTHORS" => join(t.authors, ", "),
    "CANONICAL" => p.canonical_url === nothing ? nothing : p.canonical_url(t, pkg),
    "HAS_ASSETS" => !isempty(p.assets),
    "MAKEDOCS_KWARGS" => map(((k, v),) -> k => repr(v), collect(p.makedocs_kwargs)),
    "PKG" => pkg,
    "REPO" => "$(t.host)/$(t.user)/$pkg.jl",
    "USER" => t.user,
)

function view(p::Documenter{<:GitHubPagesStyle}, t::Template, pkg::AbstractString)
    base = invoke(view, Tuple{Documenter, Template, AbstractString}, p, t, pkg)
    return merge(base, Dict("HAS_DEPLOY" => true))
end

validate(::Documenter{Nothing}, ::Template) = nothing
function validate(::Documenter{T}, t::Template) where T <: DeployStyle
    if !hasplugin(t, T)
        name = nameof(T)
        s = "Documenter: The $name plugin must be included for docs deployment to be set up"
        throw(ArgumentError(s))
    end
end

function hook(p::Documenter, t::Template, pkg_dir::AbstractString)
    pkg = basename(pkg_dir)
    docs_dir = joinpath(pkg_dir, "docs")

    # Generate files.
    make = render_file(p.make_jl, combined_view(p, t, pkg), tags(p))
    index = render_file(p.index_md, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "make.jl"), make)
    gen_file(joinpath(docs_dir, "src", "index.md"), index)

    # Copy over any assets.
    assets_dir = joinpath(docs_dir, "src", "assets")
    isempty(p.assets) || mkpath(assets_dir)
    foreach(a -> cp(a, joinpath(assets_dir, basename(a))), p.assets)

    # Create the documentation project.
    with_project(() -> Pkg.add(DOCUMENTER_DEP), docs_dir)
end

github_pages_url(t::Template, pkg::AbstractString) = "https://$(t.user).github.io/$pkg.jl"
gitlab_pages_url(t::Template, pkg::AbstractString) = "https://$(t.user).gitlab.io/$pkg.jl"

make_canonical(::Type{<:GitHubPagesStyle}) = github_pages_url
make_canonical(::Type{GitLabCI}) = gitlab_pages_url
make_canonical(::Type{Nothing}) = nothing

needs_username(::Documenter) = true
