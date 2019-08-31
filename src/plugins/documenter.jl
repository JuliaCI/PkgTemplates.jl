const DOCUMENTER_UUID = "e30172f5-a6a5-5a46-863b-614d45cd2de4"

"""
    Documenter{T<:Union{TravisCI, GitLabCI, Nothing}}(;
        assets::Vector{<:AbstractString}=String[],
        makedocs_kwargs::Dict{Symbol}=Dict(),
        canonical_url::Union{Function, Nothing}=nothing,
        make_jl::AbstractString="$(contractuser(default_file("make.jl")))",
        index_md::AbstractString="$(contractuser(default_file("index.md")))",
    ) -> Documenter{T}

The `Documenter` plugin adds support for documentation generation via [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
Documentation deployment depends on `T`, where `T` is some supported CI plugin, or `Nothing` to only support local documentation builds.

## Keyword Arguments
TODO
- `assets::Vector{<:AbstractString}=String[]`:
- `makedocs_kwargs::Dict{Symbol}=Dict{Symbol, Any}()`:
- `canonical_url::Union{Function, Nothing}=nothing`:
- `index_md::AbstractString`
- `make_jl::AbstractString`

!!! note
    If deploying documentation with Travis CI, don't forget to complete the required configuration.
    See [here](https://juliadocs.github.io/Documenter.jl/stable/man/hosting/#SSH-Deploy-Keys-1).
"""
struct Documenter{T<:Union{TravisCI, GitLabCI, Nothing}} <: Plugin
    assets::Vector{String}
    makedocs_kwargs::Dict{Symbol}
    canonical_url::Union{Function, Nothing}
    make_jl::String
    index_md::String

    # Can't use @with_kw due to some weird precompilation issues.
    function Documenter{T}(
        assets::Vector{<:AbstractString}=String[],
        makedocs_kwargs::Dict{Symbol}=Dict{Symbol, Any}(),
        canonical_url::Union{Function, Nothing}=T === TravisCI ? github_pages_url : nothing,
        index_md::AbstractString=default_file("index.md"),
        make_jl::AbstractString=default_file("make.jl"),
    ) where T <: Union{TravisCI, GitLabCI, Nothing}
        return new(assets, makedocs_kwargs, canonical_url, index_md, make_jl)
    end
end

Documenter(; kwargs...) = Documenter{Nothing}(; kwargs...)

gitignore(::Documenter) = ["/docs/build/", "/docs/site/"]

badges(::Documenter) = Badge[]
badges(::Documenter{TravisCI}) = [
    Badge(
        "Stable",
        "https://img.shields.io/badge/docs-stable-blue.svg",
        "https://{{USER}}.github.io/{{PKG}}.jl/stable",
    ),
    Badge(
        "Dev",
        "https://img.shields.io/badge/docs-dev-blue.svg",
        "https://{{USER}}.github.io/{{PKG}}.jl/dev",
    ),
]
badges(::Documenter{GitLabCI}) = Badge(
    "Dev",
    "https://img.shields.io/badge/docs-dev-blue.svg",
    "https://{{USER}}.gitlab.io/{{PKG}}.jl/dev",
)

view(p::Documenter, t::Template, pkg::AbstractString) = Dict(
    "ASSETS" => p.assets,
    "AUTHORS" => join(t.authors, ", "),
    "CANONICAL" => p.canonical_url === nothing ? nothing : p.canonical_url(t, pkg),
    "HAS_ASSETS" => !isempty(p.assets),
    "MAKEDOCS_KWARGS" => map((k, v) -> k => repr(v), collect(p.makedocs_kwargs)),
    "PKG" => pkg,
    "REPO" => "$(t.host)/$(t.user)/$pkg.jl",
    "USER" => t.user,
)

function view(p::Documenter{TravisCI}, t::Template, pkg::AbstractString)
    base = invoke(view, Tuple{Documenter, Template, AbstractString}, p, t, pkg)
    return merge(base, Dict("HAS_DEPLOY" => true))
end

function gen_plugin(p::Documenter, t::Template, pkg_dir::AbstractString)
    docs_dir = joinpath(pkg_dir, "docs")

    # Generate files.
    make = render_file(p.make_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "make.jl"), make)
    index = render_file(p.index_md, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "src", "index.md"), index)

    # Copy over any assets.
    assets_dir = joinpath(docs_dir, "src", "assets")
    isempty(p.assets) || mkpath(assets_dir)
    foreach(a -> cp(a, joinpath(assets_dir, basename(a))), p.assets)

    # Create the documentation project.
    proj = current_project()
    try
        Pkg.activate(docs_dir)
        Pkg.add(PackageSpec(; name="Documenter", uuid=DOCUMENTER_UUID))
    finally
        proj === nothing ? Pkg.activate() : Pkg.activate(proj)
    end
end

function interactive(::Type{Documenter{T}}) where T
    name = "Documenter{$T}"

    print("$name: Enter any Documenter asset files (separated by spaces) [none]: ")
    assets = split(readline())

    print("$name: Enter any extra makedocs key-value pairs (joined by '=') [none]\n> ")
    kwargs = Dict{Symbol, Any}()
    line = map(split(readline())) do kv
        k, v = split(kv, "="; limit=2)
        kwargs[Symbol(k)] = eval(Meta.parse(v))
    end

    return Documenter{T}(; assets=assets, kwargs=kwargs)
end

function interactive(::Type{Documenter})
    types = Dict(
        "None (local documentation only)" => Nothing,
        "TravisCI (GitHub Pages)" => TravisCI,
        "GitLabCI (GitLab Pages)" => GitLabCI,
    )
    options = collect(keys(types))
    menu = RadioMenu(options)
    T = types[options[request("Documenter: Select integration:", menu)]]
    return interactive(Documenter{T})
end

github_pages_url(t::Template, pkg::AbstractString) = "https://$(t.user).github.io/$pkg.jl"
