const DEFAULT_VERSION = VersionNumber(VERSION.major)

"""
    Template(interactive::Bool=false; kwargs...) -> Template

Records common information used to generate a package.

## Keyword Arguments
- `user::AbstractString=""`: GitHub (or other code hosting service) username.
  If left unset, it will take the the global Git config's value (`github.user`).
  If that is not set, an `ArgumentError` is thrown.
  This is case-sensitive for some plugins, so take care to enter it correctly!
- `host::AbstractString="github.com"`: URL to the code hosting service where your package will reside.
  Note that while hosts other than GitHub won't cause errors, they are not officially supported and they will cause certain plugins will produce incorrect output.
- `authors::Union{AbstractString, Vector{<:AbstractString}}=""`: Names that appear on the license.
  Supply a string for one author or an array for multiple.
  Similarly to `user`, it will take the value of of the global Git config's value if it is left unset.
- `dir::AbstractString=$(contractuser(Pkg.devdir()))`: Directory in which the package will go.
  Relative paths are converted to absolute ones at template creation time.
- `julia_version::VersionNumber=$DEFAULT_VERSION`: Minimum allowed Julia version.
- `ssh::Bool=false`: Whether or not to use SSH for the git remote. If `false` HTTPS will be used.
- `manifest::Bool=false`: Whether or not to commit the `Manifest.toml`.
- `git::Bool=true`: Whether or not to create a Git repository for generated packages.
- `develop::Bool=true`: Whether or not to `develop` generated packages in the active environment.
- `plugins::Vector{<:Plugin}=Plugin[]`: A list of plugins that the package will include.
- `disable_default_plugins::Vector{DataType}=DataType[]`: Default plugins to disable.
  The default plugins are [`Readme`](@ref), [`License`](@ref), [`Tests`](@ref), and [`Gitignore`](@ref).
  To override a default plugin instead of disabling it altogether, supply it via `plugins`.
- `interactive::Bool=false`: When set, creates the template interactively from user input,
  using the previous keywords as a starting point.
- `fast::Bool=false`: Only applicable when `interactive` is set.
  Skips prompts for any unsupplied keywords except `user` and `plugins`.
"""
struct Template
    user::String
    host::String
    authors::Vector{String}
    dir::String
    julia_version::VersionNumber
    ssh::Bool
    manifest::Bool
    git::Bool
    develop::Bool
    plugins::Dict{DataType, <:Plugin}
end

Template(; interactive::Bool=false, kwargs...) = make_template(Val(interactive); kwargs...)

# Non-interactive Template constructor.
function make_template(::Val{false}; kwargs...)
    user = getkw(kwargs, :user)
    if isempty(user)
        throw(ArgumentError("No username found, set one with user=username"))
    end

    host = getkw(kwargs, :host)
    host = URI(occursin("://", host) ? host : "https://$host").host

    authors = getkw(kwargs, :authors)
    authors isa Vector || (authors = map(strip, split(authors, ",")))

    dir = abspath(expanduser(getkw(kwargs, :dir)))

    disabled = getkw(kwargs, :disabled_defaults)
    defaults = [Readme, License, Tests, Gitignore]
    plugins = map(T -> T(), filter(T -> !in(T, disabled), defaults))
    append!(plugins, getkw(kwargs, :plugins))
    # This comprehensions resolves duplicate plugin types by overwriting,
    # which means that default plugins get replaced by user values.
    plugin_dict = Dict(typeof(p) => p for p in plugins)

    return Template(
        user,
        host,
        authors,
        dir,
        getkw(kwargs, :julia_version),
        getkw(kwargs, :ssh),
        getkw(kwargs, :manifest),
        getkw(kwargs, :git),
        getkw(kwargs, :develop),
        plugin_dict,
    )
end

# Does the template have a plugin of this type? Subtypes count too.
hasplugin(t::Template, ::Type{T}) where T <: Plugin = any(U -> U <: T, keys(t.plugins))

# Get a keyword, or compute some default value.
getkw(kwargs, k) = get(() -> defaultkw(k), kwargs, k)

# Default Template keyword values.
defaultkw(s::Symbol) = defaultkw(Val(s))
defaultkw(::Val{:user}) = LibGit2.getconfig("github.user", "")
defaultkw(::Val{:host}) = "https://github.com"
defaultkw(::Val{:dir}) = Pkg.devdir()
defaultkw(::Val{:julia_version}) = DEFAULT_VERSION
defaultkw(::Val{:ssh}) = false
defaultkw(::Val{:manifest}) = false
defaultkw(::Val{:git}) = true
defaultkw(::Val{:develop}) = true
defaultkw(::Val{:plugins}) = Plugin[]
defaultkw(::Val{:disabled_defaults}) = DataType[]
function defaultkw(::Val{:authors})
    name = LibGit2.getconfig("user.name", "")
    email = LibGit2.getconfig("user.email", "")
    isempty(name) && return ""
    author = name * " "
    isempty(email) || (author *= "<$email>")
    return [strip(author)]
end
