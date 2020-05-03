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
  [`Readme`](@ref), [`License`](@ref), [`Git`](@ref), [`CompatHelper`](@ref), and
  [`TagBot`](@ref).
  To disable a default plugin, pass in the negated type: `!PluginType`.
  To override a default plugin instead of disabling it, pass in your own instance.

### Interactive Mode
- `interactive::Bool=false`: In addition to specifying the template options with keywords,
  you can also build up a template by following a set of prompts.
  To create a template interactively, set this keyword to `true`.
  See also the similar [`generate`](@ref) function.

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
Template(::Val{true}; kwargs...) = interactive(Template; kwargs...)

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

"""
    getplugin(t::Template, ::Type{T<:Plugin}) -> Union{T, Nothing}

Get the plugin of type `T` from the template `t`, if it's present.
"""
function getplugin(t::Template, ::Type{T}) where T <: Plugin
    i = findfirst(p -> p isa T, t.plugins)
    return i === nothing ? nothing : t.plugins[i]
end

# Get a keyword or a default value.
getkw!(kwargs, k) = pop!(kwargs, k, defaultkw(Template, k))

# Default Template keyword values.
defaultkw(::Type{T}, s::Symbol) where T = defaultkw(T, Val(s))
defaultkw(::Type{Template}, ::Val{:authors}) = default_authors()
defaultkw(::Type{Template}, ::Val{:dir}) = contractuser(Pkg.devdir())
defaultkw(::Type{Template}, ::Val{:host}) = "github.com"
defaultkw(::Type{Template}, ::Val{:julia}) = default_version()
defaultkw(::Type{Template}, ::Val{:plugins}) = Plugin[]
defaultkw(::Type{Template}, ::Val{:user}) = default_user()

customizable(::Type{Template}) = (:disable_defaults => Vector{DataType},)

function interactive(::Type{Template}; kwargs...)
    # If the user supplied any keywords themselves, don't prompt for them.
    kwargs = Dict{Symbol, Any}(kwargs)
    options = [:user, :authors, :dir, :host, :julia, :plugins]
    customizable = setdiff(options, keys(kwargs))

    # Make sure we don't try to show a menu with < 2 options.
    isempty(customizable) && return Template(; kwargs...)
    just_one = length(customizable) == 1
    just_one && push(customizable, "None")

    println("Template keywords to customize:")
    menu = MultiSelectMenu(map(string, customizable))
    customize = customizable[sort!(collect(request(menu)))]
    just_one && lastindex(customizable) in customize && return Template(; kwargs...)

    # Prompt for each keyword.
    foreach(k -> kwargs[k] = prompt(Template, fieldtype(Template, k), k), customize)

    # We didn't include :disable_defaults above.
    # Instead, the :plugins prompt pre-selected default plugins,
    # so any default plugins that were explicitly excluded from the user's selection
    # should be disabled.
    if :plugins in customize && !haskey(kwargs, :disable_defaults)
        plugin_types = map(typeof, kwargs[:plugins])
        kwargs[:disable_defaults] = DataType[]
        foreach(map(typeof, default_plugins())) do T
            T in plugin_types || push!(kwargs[:disable_defaults], T)
        end
    end
    return Template(; kwargs...)
end

function prompt(::Type{Template}, ::Type, ::Val{:host})
    hosts = ["github.com", "gitlab.com", "bitbucket.org", "Other"]
    menu = RadioMenu(hosts)
    println("Select Git repository hosting service:")
    idx = request(menu)
    return if idx == lastindex(hosts)
        fallback_prompt(String, :host)
    else
        hosts[idx]
    end
end

function prompt(::Type{Template}, ::Type, ::Val{:julia})
    versions = map(format_version, [VERSION; map(v -> VersionNumber(1, v), 0:5)])
    push!(sort!(unique!(versions)), "Other")
    menu = RadioMenu(map(string, versions))
    println("Select minimum Julia version:")
    idx = request(menu)
    return if idx == lastindex(versions)
        fallback_prompt(VersionNumber, :julia)
    else
        VersionNumber(versions[idx])
    end
end

const CR = "\r"
const DOWN = "\eOB"

function prompt(::Type{Template}, ::Type, ::Val{:plugins})
    defaults = map(typeof, default_plugins())
    ndefaults = length(defaults)
    # Put the defaults first.
    options = unique!([defaults; concretes(Plugin)])
    menu = MultiSelectMenu(map(T -> string(nameof(T)), options); pagesize=length(options))
    println("Select plugins:")
    # Pre-select the default plugins and move the cursor to the first non-default.
    # To make this better, we need julia#30043.
    print(stdin.buffer, (CR * DOWN)^ndefaults)
    types = sort!(collect(request(menu)))
    return map(interactive, options[types])
end

# Call the default prompt method even if a specialized one exists.
fallback_prompt(T::Type, name::Symbol) = prompt(Template, T, Val(name), nothing)
