"""
    Template(; kwargs...) -> Template

Records common information used to generate a package.

# Keyword Arguments
* `user::AbstractString=LibGit2.getconfig("github.username", "")`: GitHub username.
  If left as default and there is no value configured, an error will be thrown.
  Alternatively, you can add a value to `git_config["github.username"]` to set your
  username. This is case-sensitive for some plugins, so take care to enter it correctly.
* `host::AbstractString="github.com"`: Code hosting service where your package will reside.
* `license::Union{AbstractString, Void}=nothing`: Name of the package licsense. If
  no license is specified, no license is created. [`show_license`](@ref) can be used to
  list all available licenses, or to print out a particular license's text.
* `authors::Union{AbstractString, Array}=LibGit2.getconfig("user.name", "")`: Names that
  appear on the license. Supply a string for one author, and an array for multiple.
* `years::Union{Int, AbstractString}=string(Dates.year(Dates.today()))`: Copyright years
  on the license. Can be supplied by a number, or a string such as "2016 - 2017".
* `dir::AbstractString=Pkg.dir()`: Directory in which the package will go.
* `julia_version::VersionNumber=VERSION`: Minimum allowed Julia version.
* `git_config::Dict{String, String}=Dict{String, String}()`: Git configuration options.
* `plugins::Vector{Plugin}`: A list of `Plugin`s that the package will include.
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
        user::AbstractString=LibGit2.getconfig("github.username", ""),
        host::AbstractString="https://github.com",
        license::Union{AbstractString, Void}=nothing,
        authors::Union{AbstractString, Array}=LibGit2.getconfig("user.name", ""),
        years::Union{Int, AbstractString}=string(Dates.year(Dates.today())),
        dir::AbstractString=Pkg.dir(),
        julia_version::VersionNumber=VERSION,
        git_config::Dict=Dict(),
        plugins::Vector{P}=Vector{Plugin}(),
    ) where P <: Plugin
        # If no username was set or found, look for one in the supplied git config.
        if isempty(user) && (!haskey(git_config, "github.username") ||
            isempty(git_config["github.username"]))
            throw(ArgumentError("No GitHub username found, set one with user=username"))
        elseif isempty(user)
            user = git_config["github.username"]
        end

        host = URI(startswith(host, "https://") ? host : "https://$host").host

        if license != nothing && !isfile(joinpath(LICENSE_DIR, license))
            throw(ArgumentError("License '$license' is not available"))
        end

        # If an explicitly supplied git config contains a name and the author name was not
        # explicitly supplied, then take the git config's name as the author name.
        if haskey(git_config, "user.name") && authors == LibGit2.getconfig("user.name", "")
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
