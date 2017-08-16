"""
    Template(; kwargs...) -> Template

Records common information used to generate a package.

# Keyword Arguments
* `user::AbstractString="")`: GitHub username. If left  unset, it will try to take the
  value of a supplied git config's "github.username" key, then the global git config's
  value. If neither is set, an `ArgumentError` is thrown.
  **This is case-sensitive for some plugins, so take care to enter it correctly.**
* `host::AbstractString="github.com"`: URL to the code hosting service where your package
  will reside.
* `license::Union{AbstractString, Void}=nothing`: Name of the package license. If
  no license is specified, no license is created. [`show_license`](@ref) can be used to
  list all available licenses, or to print out a particular license's text.
* `authors::Union{AbstractString, Array}=""`: Names that appear on the license. Supply a
  string for one author, and an array for multiple. Similarly to `user`, it will try to
  take the value of a supplied git config's "user.name" key, then the global git config's
  value, if it is left unset
* `years::Union{Int, AbstractString}=string(Dates.year(Dates.today()))`: Copyright years
  on the license. Can be supplied by a number, or a string such as "2016 - 2017".
* `dir::AbstractString=Pkg.dir()`: Directory in which the package will go.
* `julia_version::VersionNumber=VERSION`: Minimum allowed Julia version.
* `git_config::Dict{String, String}=Dict{String, String}()`: Git configuration options.
* `plugins::Vector{Plugin}`: A list of `Plugin`s that the package will include.

**Note**: When you create a `Template`, a temporary directory is created with
`mktempdir()`. This directory will be removed after you call [`generate`](@ref).
Creating multiple packages in succession with the same instance of a template will still
work, but there is a miniscule chance of another process sharing the temporary directory,
which could result in the created package repository containing untracked files that
don't belong.
"""
@auto_hash_equals struct Template
    user::AbstractString
    host::AbstractString
    license::Union{AbstractString, Void}
    authors::Union{AbstractString, Array}
    years::AbstractString
    dir::AbstractString
    temp_dir::AbstractString
    julia_version::VersionNumber
    git_config::Dict
    plugins::Dict{DataType, Plugin}

    function Template(;
        user::AbstractString="",
        host::AbstractString="https://github.com",
        license::Union{AbstractString, Void}=nothing,
        authors::Union{AbstractString, Array}="",
        years::Union{Int, AbstractString}=string(Dates.year(Dates.today())),
        dir::AbstractString=Pkg.dir(),
        julia_version::VersionNumber=VERSION,
        git_config::Dict=Dict(),
        plugins::Vector{P}=Vector{Plugin}(),
    ) where P <: Plugin
        # If no username was set, look for one in a supplied git config,
        # and then in the global git config.
        if isempty(user)
            user = get(
                git_config, "github.username",
                LibGit2.getconfig("github.username", ""),
            )
        end
        if isempty(user)
            throw(ArgumentError("No GitHub username found, set one with user=username"))
        end

        host = URI(startswith(host, "https://") ? host : "https://$host").host

        if license != nothing && !isfile(joinpath(LICENSE_DIR, license))
            throw(ArgumentError("License '$license' is not available"))
        end

        # If no author was set, look for one in the supplied git config,
        # and then in the global git config.
        if isempty(authors)
            authors = get(git_config, "user.name", LibGit2.getconfig("user.name", ""))
        elseif isa(authors, Array)
            authors = join(authors, ", ")
        end

        years = string(years)

        temp_dir = mktempdir()

        plugin_dict = Dict{DataType, Plugin}(typeof(p) => p for p in plugins)
        if (length(plugins) != length(plugin_dict))
            warn("Plugin list contained duplicates, only the last of each type was kept")
        end

        new(
            user, host, license, authors, years, dir, temp_dir,
            julia_version, git_config, plugin_dict
        )
    end
end
