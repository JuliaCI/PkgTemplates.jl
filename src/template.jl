"""
    Template(; kwargs...) -> Template

Records common information used to generate a package. If you don't wish to manually
create a template, you can use [`interactive`](@ref) instead.

# Keyword Arguments
* `user::AbstractString="")`: GitHub username. If left  unset, it will try to take the
  value of a supplied git config's "github.username" key, then the global git config's
  value. If neither is set, an `ArgumentError` is thrown.
  **This is case-sensitive for some plugins, so take care to enter it correctly.**
* `host::AbstractString="github.com"`: URL to the code hosting service where your package
  will reside. Note that while hosts other than GitHub won't cause errors, they are not
  officially supported and they will cause certain plugins will produce incorrect output.
  For example, [`AppVeyor`](@ref)'s badge image will point to a GitHub-specific URL,
  regardless of the value of `host`.
* `license::Union{AbstractString, Void}=nothing`: Name of the package license. If
  no license is specified, no license is created. [`show_license`](@ref) can be used to
  list all available licenses, or to print out a particular license's text.
* `authors::Union{AbstractString, Array}=""`: Names that appear on the license. Supply a
  string for one author, and an array for multiple. Similarly to `user`, it will try to
  take the value of a supplied git config's "user.name" key, then the global git config's
  value, if it is left unset
* `years::Union{Int, AbstractString}=Dates.year(now())`: Copyright years on the license.
  Can be supplied by a number, or a string such as "2016 - 2017".
* `dir::AbstractString=Pkg.dir()`: Directory in which the package will go.
* `julia_version::VersionNumber=VERSION`: Minimum allowed Julia version.
* `requirements::Vector{String}=String[]`: Package requirements. If there are duplicate
  requirements with different versions, i.e. ["PkgTemplates", "PkgTemplates 0.1"],
  an `ArgumentError` is thrown.
  Each entry in this array will be copied into the `REQUIRE` file of packages generated
  with this template.
* `git_config::Dict{String, String}=Dict{String, String}()`: Git configuration options.
* `plugins::Plugin[]`: A list of `Plugin`s that the package will include.

# Notes
When you create a `Template`, a temporary directory is created with
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
    requirements::Vector{AbstractString}
    git_config::Dict
    plugins::Dict{DataType, Plugin}

    function Template(;
        user::AbstractString="",
        host::AbstractString="https://github.com",
        license::Union{AbstractString, Void}=nothing,
        authors::Union{AbstractString, Array}="",
        years::Union{Int, AbstractString}=Dates.year(now()),
        dir::AbstractString=Pkg.dir(),
        julia_version::VersionNumber=VERSION,
        requirements::Vector{String}=String[],
        git_config::Dict=Dict(),
        plugins::Vector{P}=Plugin[],
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

        requirements_dedup = collect(Set(requirements))
        diff = length(requirements) - length(requirements_dedup)
        names = [tokens[1] for tokens in split.(requirements_dedup)]
        if length(names) > length(Set(names))
            throw(ArgumentError(
                "requirements contains duplicate packages with conflicting versions"
            ))
        elseif diff > 0
            warn("Removed $(diff) duplicate$(diff == 1 ? "" : "s") from requirements")
        end

        plugin_dict = Dict{DataType, Plugin}(typeof(p) => p for p in plugins)
        if (length(plugins) != length(plugin_dict))
            warn("Plugin list contained duplicates, only the last of each type was kept")
        end

        new(
            user, host, license, authors, years, dir, temp_dir,
            julia_version, requirements_dedup, git_config, plugin_dict
        )
    end
end

"""
    interactive_template() -> Template

Interactively generate a [`Template`](@ref).
"""
function interactive()
    info("Generating template... default values are shown in [brackets]")
    # Getting the leaf types in a separate thread eliminates an awkward wait after
    # "Select plugins" is printed.
    plugin_types = @spawn leaves(Plugin)
    kwargs = Dict{Symbol, Any}()

    default_user = LibGit2.getconfig("github.username", "")
    print("Enter your username [$(isempty(default_user) ? "REQUIRED" : default_user)]: ")
    user = readline()
    kwargs[:user] = if !isempty(user)
        user
    elseif !isempty(default_user)
        default_user
    else
        throw(ArgumentError("Username is required"))
    end

    default_host = "github.com"
    print("Enter the code hosting service [$default_host]: ")
    host = readline()
    kwargs[:host] = isempty(host) ? default_host : host

    println("Select a license:")
    io = IOBuffer()
    show_license(; io=io)
    licenses = [nothing => nothing, collect(LICENSES)...]
    menu = RadioMenu(["None", split(String(take!(io)), "\n")...])
    # If the user breaks out of the menu with C-c, the result is -1, the absolute value of
    # which correponds to no license.
    kwargs[:license] = licenses[abs(request(menu))].first

    default_authors = LibGit2.getconfig("user.name", "")
    default_str = isempty(default_authors) ? "None" : default_authors
    print("Enter the package author(s) [$default_str]: ")
    authors = readline()
    kwargs[:authors] = isempty(authors) ? default_authors : authors

    default_years = Dates.year(now())
    print("Enter the copyright year(s) [$default_years]: ")
    years = readline()
    kwargs[:years] = isempty(years) ? default_years : years

    default_dir = Pkg.dir()
    print("Enter the path to the package directory [$default_dir]: ")
    dir = readline()
    kwargs[:dir] = isempty(dir) ? default_dir : dir

    default_julia_version = VERSION
    print("Enter the minimum Julia version [$default_julia_version]: ")
    julia_version = readline()
    kwargs[:julia_version] = if isempty(julia_version)
        default_julia_version
    else
        VersionNumber(julia_version)
    end

    print("Enter any Julia package requirements, (separated by spaces) []: ")
    requirements = String.(split(readline()))

    git_config = Dict()
    print("Enter any Git key-value pairs (one at a time, separated by spaces) [None]: ")
    while true
        tokens = split(readline())
        isempty(tokens) && break
        if haskey(git_config, tokens[1])
            warn("Duplicate key '$(tokens[1])': Replacing old value '$(tokens[2])'")
        end
        git_config[tokens[1]] = tokens[2]
    end
    kwargs[:git_config] = git_config

    println("Select plugins:")
    plugin_types = fetch(plugin_types)
    type_names = map(t -> split(string(t), ".")[end], plugin_types)
    menu = MultiSelectMenu(String.(type_names); pagesize=length(type_names))
    selected = collect(request(menu))
    kwargs[:plugins] = Vector{Plugin}(
        map(t -> interactive(t), getindex(plugin_types, selected)),
    )

    return Template(; kwargs...)
end

"""
    leaves(t:Type) -> Vector{DataType}

Get all concrete subtypes of `t`.
"""
leaves(t::Type) = isleaftype(t) ? t : vcat(leaves.(subtypes(t))...)
