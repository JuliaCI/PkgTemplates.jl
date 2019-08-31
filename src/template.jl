default_plugins() = [Gitignore(), License(), Readme(), Tests()]
default_user() = LibGit2.getconfig("github.user", "")
default_version() = VersionNumber(VERSION.major)

function default_authors()
    name = LibGit2.getconfig("user.name", "")
    isempty(name) && return ""
    email = LibGit2.getconfig("user.email", "")
    return isempty(email) ? name : "$name <$email>"
end

"""
    Template(; interactive::Bool=false, kwargs...) -> Template

Records common information used to generate a package.

## Keyword Arguments

### User Options
- `user::AbstractString="$(default_user())"`: GitHub (or other code hosting service) username.
  The default value comes from the global Git config (`github.user`).
  If no value is obtained, an `ArgumentError` is thrown.
- `authors::Union{AbstractString, Vector{<:AbstractString}}="$(default_authors())"`: Package authors.
  Supply a string for one author or an array for multiple.
  Like `user`, it takes its default value from the global Git config (`user.name` and `user.email`).

### Package Options
- `host::AbstractString="github.com"`: URL to the code hosting service where packages will reside.
- `dir::AbstractString="$(contractuser(Pkg.devdir()))"`: Directory to place packages in.
- `julia_version::VersionNumber=$(repr(default_version()))`: Minimum allowed Julia version.
- `develop::Bool=true`: Whether or not to `develop` new packages in the active environment.

### Git Options
- `git::Bool=true`: Whether or not to create a Git repository for new packages.
- `ssh::Bool=false`: Whether or not to use SSH for the Git remote.
  If left unset, HTTPS will be used.
- `manifest::Bool=false`: Whether or not to commit the `Manifest.toml`.

### Template Plugins
- `plugins::Vector{<:Plugin}=Plugin[]`: A list of [`Plugin`](@ref)s used by the template.
- `disable_defaults::Vector{DataType}=DataType[]`: Default plugins to disable.
  The default plugins are [`Readme`](@ref), [`License`](@ref), [`Tests`](@ref), and [`Gitignore`](@ref).
  To override a default plugin instead of disabling it altogether, supply it via `plugins`.

### Interactive Usage
- `interactive::Bool=false`: When set, the template is created interactively, filling unset keywords with user input.
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

    authors = getkw(kwargs, :authors)
    authors isa Vector || (authors = map(strip, split(authors, ",")))

    host = replace(getkw(kwargs, :host), r".*://" => "")

    dir = abspath(expanduser(getkw(kwargs, :dir)))

    disabled = getkw(kwargs, :disable_defaults)
    enabled = filter(p -> !(typeof(p) in disabled), default_plugins())
    append!(enabled, getkw(kwargs, :plugins))
    # This comprehension resolves duplicate plugin types by overwriting,
    # which means that default plugins get replaced by user values.
    plugins = Dict(typeof(p) => p for p in enabled)

    return Template(
        authors,
        getkw(kwargs, :develop),
        dir,
        getkw(kwargs, :git),
        host,
        getkw(kwargs, :julia_version),
        getkw(kwargs, :manifest),
        plugins,
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
defaultkw(::Val{:authors}) = default_authors()
defaultkw(::Val{:develop}) = true
defaultkw(::Val{:dir}) = Pkg.devdir()
defaultkw(::Val{:disable_defaults}) = DataType[]
defaultkw(::Val{:git}) = true
defaultkw(::Val{:host}) = "github.com"
defaultkw(::Val{:julia_version}) = default_version()
defaultkw(::Val{:manifest}) = false
defaultkw(::Val{:plugins}) = Plugin[]
defaultkw(::Val{:ssh}) = false
defaultkw(::Val{:user}) = default_user()
