default_user() = LibGit2.getconfig("github.user", "")
default_version() = VersionNumber(VERSION.major)
default_plugins() = [
    CompatHelper(),
    ProjectFile(),
    SrcDir(),
    Git(),
    License(),
    Readme(),
    Tests(),
    TagBot(),
]

function default_authors()
    name = LibGit2.getconfig("user.name", "")
    isempty(name) && return "contributors"
    email = LibGit2.getconfig("user.email", "")
    authors = isempty(email) ? name : "$name <$email>"
    return "$authors and contributors"
end

"""
    Template(; kwargs...)

A configuration used to generate packages.

## Keyword Arguments

### User Options
- `user::AbstractString="$(default_user())"`: GitHub (or other code hosting service) username.
  The default value comes from the global Git config (`github.user`).
  If no value is obtained, many plugins that use this value will not work.
- `authors::Union{AbstractString, Vector{<:AbstractString}}="$(default_authors())"`: Package authors.
  Like `user`, it takes its default value from the global Git config
  (`user.name` and `user.email`).

### Package Options
- `dir::AbstractString="$(contractuser(Pkg.devdir()))"`: Directory to place packages in.
- `host::AbstractString="github.com"`: URL to the code hosting service where packages will reside.
- `julia::VersionNumber=$(repr(default_version()))`: Minimum allowed Julia version.

### Template Plugins
- `plugins::Vector{<:Plugin}=Plugin[]`: A list of [`Plugin`](@ref)s used by the template.
  The default plugins are [`ProjectFile`](@ref), [`SrcDir`](@ref), [`Tests`](@ref),
  [`Readme`](@ref), [`License`](@ref), and [`Git`](@ref).
  To disable a default plugin, pass in the negated type: `!PluginType`.
  To override a default plugin instead of disabling it, pass in your own instance.

---

To create a package from a `Template`, use the following syntax:

```julia
julia> t = Template();

julia> t("PkgName")
```
"""
struct Template
    authors::Vector{String}
    dir::String
    host::String
    julia::VersionNumber
    plugins::Vector{<:Plugin}
    user::String
end

Template(; interactive::Bool=false, kwargs...) = Template(Val(interactive); kwargs...)
Template(::Val{true}) = interactive(Template)

function Template(::Val{false}; kwargs...)
    kwargs = Dict(kwargs)

    user = getkw!(kwargs, :user)
    dir = abspath(expanduser(getkw!(kwargs, :dir)))
    host = replace(getkw!(kwargs, :host), r".*://" => "")
    julia = getkw!(kwargs, :julia)

    authors = getkw!(kwargs, :authors)
    authors isa Vector || (authors = map(strip, split(authors, ",")))

    # User-supplied plugins come first, so that deduping the list will remove the defaults.
    plugins = Vector{Any}(collect(getkw!(kwargs, :plugins)))
    disabled = map(d -> first(typeof(d).parameters), filter(p -> p isa Disabled, plugins))
    filter!(p -> p isa Plugin, plugins)
    append!(plugins, filter(p -> !(typeof(p) in disabled), default_plugins()))
    plugins = Vector{Plugin}(sort(unique(typeof, plugins); by=string))

    if isempty(user)
        foreach(plugins) do p
            if needs_username(p)
                T = nameof(typeof(p))
                s = """$T: Git hosting service username is required, set one with keyword `user="<username>"`"""
                throw(ArgumentError(s))
            end
        end
    end

    if !isempty(kwargs)
        @warn "Unrecognized keywords were supplied, see the documentation for help" kwargs
    end

    t = Template(authors, dir, host, julia, plugins, user)
    foreach(p -> validate(p, t), t.plugins)
    return t
end

"""
    (::Template)(pkg::AbstractString)

Generate a package named `pkg` from a [`Template`](@ref).
"""
function (t::Template)(pkg::AbstractString)
    endswith(pkg, ".jl") && (pkg = pkg[1:end-3])
    pkg_dir = joinpath(t.dir, pkg)
    ispath(pkg_dir) && throw(ArgumentError("$pkg_dir already exists"))
    mkpath(pkg_dir)

    try
        foreach((prehook, hook, posthook)) do h
            @info "Running $(nameof(h))s"
            foreach(sort(t.plugins; by=p -> priority(p, h), rev=true)) do p
                h(p, t, pkg_dir)
            end
        end
    catch
        rm(pkg_dir; recursive=true, force=true)
        rethrow()
    end

    @info "New package is at $pkg_dir"
end

function Base.:(==)(a::Template, b::Template)
    return a.authors == b.authors &&
        a.dir == b.dir &&
        a.host == b.host &&
        a.julia == b.julia &&
        a.user == b.user &&
        all(map(==, a.plugins, b.plugins))
end

# Does the template have a plugin that satisfies some predicate?
hasplugin(t::Template, f::Function) = any(f, t.plugins)
hasplugin(t::Template, ::Type{T}) where T <: Plugin = hasplugin(t, p -> p isa T)

# Get a plugin by type.
function getplugin(t::Template, ::Type{T}) where T <: Plugin
    i = findfirst(p -> p isa T, t.plugins)
    return i === nothing ? nothing : t.plugins[i]
end

# Get a keyword or a default value.
getkw!(kwargs, k) = pop!(kwargs, k, defaultkw(Template, k))

# Default Template keyword values.
defaultkw(::Type{T}, s::Symbol) where T = defaultkw(T, Val(s))
defaultkw(::Type{Template}, ::Val{:authors}) = default_authors()
defaultkw(::Type{Template}, ::Val{:dir}) = Pkg.devdir()
defaultkw(::Type{Template}, ::Val{:host}) = "github.com"
defaultkw(::Type{Template}, ::Val{:julia}) = default_version()
defaultkw(::Type{Template}, ::Val{:plugins}) = Plugin[]
defaultkw(::Type{Template}, ::Val{:user}) = default_user()

extra_customizable(::Type{Template}) = (:disable_defaults => Vector{DataType},)
