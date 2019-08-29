const DEFAULT_USER = LibGit2.getconfig("github.user", "")
const DEFAULT_VERSION = VersionNumber(VERSION.major)
const DEFAULT_AUTHORS = let
    name = LibGit2.getconfig("user.name", "")
    email = LibGit2.getconfig("user.email", "")
    if isempty(name)
        ""
    else
        isempty(email) ? name : "$name <$email>"
    end
end

"""
    Template(; interactive::Bool=false, kwargs...) -> Template

Records common information used to generate a package.

## Keyword Arguments

### User Options
- `user::AbstractString="$DEFAULT_USER"`: GitHub (or other code hosting service) username.
  The default value comes from the global Git config (`github.user`).
  If no value is obtained, an `ArgumentError` is thrown.
- `authors::Union{AbstractString, Vector{<:AbstractString}}="$DEFAULT_AUTHORS"`: Package authors.
  Supply a string for one author or an array for multiple.
  Like `user`, it takes its default value from the global Git config (`user.name` and `user.email`).

### Package Options
- `host::AbstractString="github.com"`: URL to the code hosting service where packages will reside.
- `dir::AbstractString="$(contractuser(Pkg.devdir()))"`: Directory to place packages in.
- `julia_version::VersionNumber=$(repr(DEFAULT_VERSION))`: Minimum allowed Julia version.
- `develop::Bool=true`: Whether or not to `develop` new packages in the active environment.

### Git Options
- `git::Bool=true`: Whether or not to create a Git repository for new packages.
- `ssh::Bool=false`: Whether or not to use SSH for the Git remote.
  If left unset, HTTPS will be used.
- `manifest::Bool=false`: Whether or not to commit the `Manifest.toml`.

### Template Plugins
- `plugins::Vector{<:Plugin}=Plugin[]`: A list of [`Plugin`](@ref)s used by the template.
- `disabled_defaults::Vector{DataType}=DataType[]`: Default plugins to disable.
  The default plugins are [`Readme`](@ref), [`License`](@ref), [`Tests`](@ref), and [`Gitignore`](@ref).
  To override a default plugin instead of disabling it altogether, supply it via `plugins`.

### Interactive Usage
- `interactive::Bool=false`: When set, the template is created interactively, filling unset keywords with user input.
- `fast::Bool=false`: Skips prompts for any unsupplied keywords except `user` and `plugins`, accepting default values.
"""
struct Template
    authors::Vector{String}
    develop::Bool
    dir::String
    git::Bool
    host::String
    julia_version::VersionNumber
    manifest::Bool
    plugins::Dict{DataType, <:Plugin}
    ssh::Bool
    user::String
end

Template(; interactive::Bool=false, kwargs...) = Template(Val(interactive); kwargs...)

# Non-interactive constructor.
function Template(::Val{false}; kwargs...)
    user = getkw(kwargs, :user)
    isempty(user) && throw(ArgumentError("No user set, please pass user=username"))

    host = getkw(kwargs, :host)
    host = URI(occursin("://", host) ? host : "https://$host").host

    authors = getkw(kwargs, :authors)
    authors isa Vector || (authors = map(strip, split(authors, ",")))

    dir = abspath(expanduser(getkw(kwargs, :dir)))

    disabled = getkw(kwargs, :disabled_defaults)
    defaults = [Readme, License, Tests, Gitignore]
    plugins = map(T -> T(), filter(T -> !(T in disabled), defaults))
    append!(plugins, getkw(kwargs, :plugins))
    # This comprehension resolves duplicate plugin types by overwriting,
    # which means that default plugins get replaced by user values.
    plugin_dict = Dict(typeof(p) => p for p in plugins)

    return Template(
        authors,
        getkw(kwargs, :develop),
        dir,
        getkw(kwargs, :git),
        host,
        getkw(kwargs, :julia_version),
        getkw(kwargs, :manifest),
        plugin_dict,
        getkw(kwargs, :ssh),
        user,
    )
end

# Does the template have a plugin that satisfies some predicate?
hasplugin(t::Template, f::Function) = any(f, keys(t.plugins))
hasplugin(t::Template, ::Type{T}) where T <: Plugin = hasplugin(t, U -> U <: T)

# Get a keyword, or compute some default value.
getkw(kwargs, k) = get(() -> defaultkw(k), kwargs, k)

# Default Template keyword values.
defaultkw(s::Symbol) = defaultkw(Val(s))
defaultkw(::Val{:authors}) = DEFAULT_AUTHORS
defaultkw(::Val{:develop}) = true
defaultkw(::Val{:dir}) = Pkg.devdir()
defaultkw(::Val{:disabled_defaults}) = DataType[]
defaultkw(::Val{:git}) = true
defaultkw(::Val{:host}) = "github.com"
defaultkw(::Val{:julia_version}) = DEFAULT_VERSION
defaultkw(::Val{:manifest}) = false
defaultkw(::Val{:plugins}) = Plugin[]
defaultkw(::Val{:ssh}) = false
defaultkw(::Val{:user}) = DEFAULT_USER
