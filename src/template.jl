"""
    dev_dir() -> String

Get the default development directory (~/.julia/dev).
"""
dev_dir() = joinpath(first(DEPOT_PATH), "dev")

"""
    Template(; kwargs...) -> Template

Records common information used to generate a package. If you don't wish to manually
create a template, you can use [`interactive_template`](@ref) instead.

# Keyword Arguments
* `user::AbstractString=""`: GitHub username. If left  unset, it will try to take the
  value of a supplied git config's "github.user" key, then the global git config's
  value. If neither is set, an `ArgumentError` is thrown.
  **This is case-sensitive for some plugins, so take care to enter it correctly.**
* `host::AbstractString="github.com"`: URL to the code hosting service where your package
  will reside. Note that while hosts other than GitHub won't cause errors, they are not
  officially supported and they will cause certain plugins will produce incorrect output.
  For example, [`AppVeyor`](@ref)'s badge image will point to a GitHub-specific URL,
  regardless of the value of `host`.
* `license::AbstractString="MIT"`: Name of the package license. If an empty string is
  given, no license is created. [`available_licenses`](@ref) can be used to list all
  available licenses, and [`show_license`](@ref) can be used to print out a particular
  license's text.
* `authors::Union{AbstractString, Vector{<:AbstractString}}=""`: Names that appear on the
  license. Supply a string for one author or an array for multiple. Similarly to `user`,
  it will try to take the value of a supplied git config's "user.name" key, then the global
  git config's value, if it is left unset.
* `years::Union{Integer, AbstractString}=$(Dates.year(Dates.today()))`: Copyright years on
  the license. Can be supplied by a number, or a string such as "2016 - 2017".
* `dir::AbstractString=$(dev_dir())`: Directory in which the package will go. Relative
  paths are converted to absolute ones at template creation time.
* `julia_version::VersionNumber=VERSION`: Minimum allowed Julia version.
* `ssh::Bool=false`: Whether or not to use SSH for the remote.
* `requirements::Vector{<:AbstractString}=String[]`: Package requirements. If there are
  duplicate requirements with different versions, i.e. ["PkgTemplates", "PkgTemplates
  0.1"], an `ArgumentError` is thrown. Each entry in this array will be copied into the
  `REQUIRE` file of packages generated with this template.
* `gitconfig::Dict=Dict()`: Git configuration options.
* `plugins::Vector{<:Plugin}=Plugin[]`: A list of `Plugin`s that the package will include.
"""
@auto_hash_equals struct Template
    user::AbstractString
    host::AbstractString
    license::AbstractString
    authors::AbstractString
    years::AbstractString
    dir::AbstractString
    julia_version::VersionNumber
    ssh::Bool
    requirements::Vector{AbstractString}
    gitconfig::Dict
    plugins::Dict{DataType, Plugin}

    function Template(;
        user::AbstractString="",
        host::AbstractString="https://github.com",
        license::AbstractString="MIT",
        authors::Union{AbstractString, Vector{<:AbstractString}}="",
        years::Union{Integer, AbstractString}=Dates.year(Dates.today()),
        dir::AbstractString=dev_dir(),
        julia_version::VersionNumber=VERSION,
        ssh::Bool=false,
        requirements::Vector{<:AbstractString}=String[],
        gitconfig::Dict=Dict(),
        plugins::Vector{<:Plugin}=Plugin[],
    )
        # If no username was set, look for one in a supplied git config,
        # and then in the global git config.
        if isempty(user)
            user = get(gitconfig, "github.user", LibGit2.getconfig("github.user", ""))
        end
        if isempty(user)
            throw(ArgumentError("No GitHub username found, set one with user=username"))
        end

        host = URI(startswith(host, "https://") ? host : "https://$host").host

        if !isempty(license) && !isfile(joinpath(LICENSE_DIR, license))
            throw(ArgumentError("License '$license' is not available"))
        end

        # If no author was set, look for one in the supplied git config,
        # and then in the global git config.
        if isempty(authors)
            authors = get(gitconfig, "user.name", LibGit2.getconfig("user.name", ""))
        elseif isa(authors, Vector)
            authors = join(authors, ", ")
        end

        years = string(years)

        dir = abspath(expanduser(dir))

        requirements_dedup = collect(Set(requirements))
        diff = length(requirements) - length(requirements_dedup)
        names = map(t -> first(t), split.(requirements_dedup))
        if length(names) > length(Set(names))
            throw(ArgumentError(
                "requirements contains duplicate packages with conflicting versions"
            ))
        elseif diff > 0
            @warn "Removed $(diff) duplicate$(diff == 1 ? "" : "s") from requirements"
        end

        plugin_dict = Dict{DataType, Plugin}(typeof(p) => p for p in plugins)
        if (length(plugins) != length(plugin_dict))
            @warn "Plugin list contained duplicates, only the last of each type was kept"
        end

        new(
            user, host, license, authors, years, dir, julia_version, ssh,
            requirements_dedup, gitconfig, plugin_dict,
        )
    end
end

function Base.show(io::IO, t::Template)
    maybe_none(s::AbstractString) = isempty(string(s)) ? "None" : string(s)
    spc = "  "

    println(io, "Template:")
    println(io, "$spc→ User: $(maybe_none(t.user))")
    println(io, "$spc→ Host: $(maybe_none(t.host))")

    print(io, "$spc→ License: ")
    if isempty(t.license)
        println(io, "None")
    else
        println(io, "$(t.license) ($(t.authors) $(t.years))")
    end

    println(io, "$spc→ Package directory: $(replace(maybe_none(t.dir), homedir() => "~"))")
    println(io, "$spc→ Minimum Julia version: v$(version_floor(t.julia_version))")
    println(io, "$spc→ SSH remote: $(t.ssh ? "Yes" : "No")")

    n = length(t.requirements)
    s = n == 1 ? "" : "s"
    print(io, "$spc→ $n package requirement$s")

    if isempty(t.requirements)
        println(io)
    else
        println(io, ": $(join(t.requirements, ", "))")
    end

    print(io, "$spc→ Git configuration options:")
    if isempty(t.gitconfig)
        println(io, " None")
    else
        println(io)
        for k in sort(collect(keys(t.gitconfig)); by=string)
            println(io, "$(spc^2)• $k = $(t.gitconfig[k])")
        end
    end

    print(io, "$spc→ Plugins:")
    if isempty(t.plugins)
        print(io, " None")
    else
        for plugin in sort(collect(values(t.plugins)); by=string)
            println(io)
            buf = IOBuffer()
            show(buf, plugin)
            print(io, "$(spc^2)• ")
            print(io, join(split(String(take!(buf)), "\n"), "\n$(spc^2)"))
        end
    end
end

"""
    interactive_template(; fast::Bool=false) -> Template

Interactively create a [`Template`](@ref). If `fast` is set, defaults will be assumed for
all values except username and plugins.
"""
function interactive_template(; fast::Bool=false)
    @info "Default values are shown in [brackets]"
    # Getting the leaf types in a separate thread eliminates an awkward wait after
    # "Select plugins" is printed.
    plugin_types = @spawn leaves(Plugin)
    kwargs = Dict{Symbol, Any}()

    default_user = LibGit2.getconfig("github.user", "")
    print("Enter your username [$(isempty(default_user) ? "REQUIRED" : default_user)]: ")
    user = readline()
    kwargs[:user] = if !isempty(user)
        user
    elseif !isempty(default_user)
        default_user
    else
        throw(ArgumentError("Username is required"))
    end

    kwargs[:host] = if fast
        "https://github.com"
    else
        default_host = "github.com"
        print("Enter the code hosting service [$default_host]: ")
        host = readline()
        isempty(host) ? default_host : host
    end

    kwargs[:license] = if fast
        "MIT"
    else
        println("Select a license:")
        io = IOBuffer()
        available_licenses(io)
        licenses = ["" => "", collect(LICENSES)...]
        menu = RadioMenu(String["None", split(String(take!(io)), "\n")...])
        # If the user breaks out of the menu with Ctrl-c, the result is -1, the absolute
        # value of which correponds to no license.
        licenses[abs(request(menu))].first
    end

    # We don't need to ask for authors or copyright years if there is no license,
    # because the license is the only place that they matter.

    kwargs[:authors] = if fast || isempty(kwargs[:license])
        LibGit2.getconfig("user.name", "")
    else
        default_authors = LibGit2.getconfig("user.name", "")
        default_str = isempty(default_authors) ? "None" : default_authors
        print("Enter the package author(s) [$default_str]: ")
        authors = readline()
        isempty(authors) ? default_authors : authors
    end

    kwargs[:years] = if fast || isempty(kwargs[:license])
        Dates.year(Dates.today())
    else
        default_years = Dates.year(Dates.today())
        print("Enter the copyright year(s) [$default_years]: ")
        years = readline()
        isempty(years) ? default_years : years
    end

    kwargs[:dir] = if fast
        dev_dir()
    else
        default_dir = dev_dir()
        print("Enter the path to the package directory [$default_dir]: ")
        dir = readline()
        isempty(dir) ? default_dir : dir
    end

    kwargs[:julia_version] = if fast
        VERSION
    else
        default_julia_version = VERSION
        print("Enter the minimum Julia version [$(version_floor(default_julia_version))]: ")
        julia_version = readline()
        isempty(julia_version) ? default_julia_version : VersionNumber(julia_version)
    end

    kwargs[:ssh] = if fast
        false
    else
        print("Set remote to SSH? [no]: ")
        in(uppercase(readline()), ["Y", "YES", "T", "TRUE"])
    end

    kwargs[:requirements] = if fast
        String[]
    else
        print("Enter any Julia package requirements, (separated by spaces) []: ")
        String.(split(readline()))
    end

    kwargs[:gitconfig] = if fast
        Dict()
    else
        gitconfig = Dict()
        print("Enter any Git key-value pairs (one per line, separated by spaces) [None]: ")
        while true
            line = readline()
            isempty(line) && break
            tokens = split(line, " ", limit=2)
            if haskey(gitconfig, tokens[1])
                @warn "Duplicate key '$(tokens[1])': Replacing old value '$(tokens[2])'"
            end
            gitconfig[tokens[1]] = tokens[2]
        end
        gitconfig
    end

    println("Select plugins:")
    # Only include plugin types which have an `interactive` method.
    plugin_types = filter(t -> hasmethod(interactive, (Type{t},)), fetch(plugin_types))
    type_names = map(t -> split(string(t), ".")[end], plugin_types)
    menu = MultiSelectMenu(String.(type_names); pagesize=length(type_names))
    selected = collect(request(menu))
    kwargs[:plugins] = Vector{Plugin}(
        map(t -> interactive(t), getindex(plugin_types, selected))
    )

    return Template(; kwargs...)
end

"""
    leaves(t:Type) -> Vector{DataType}

Get all concrete subtypes of `t`.
"""
leaves(t::Type)::Vector{DataType} = isconcretetype(t) ? [t] : vcat(leaves.(subtypes(t))...)
