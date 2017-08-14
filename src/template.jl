"""
    Template(; kwargs...) -> Template

Records common information used to generate a package.

# Keyword Arguments
* `remote_prefix::AbstractString`: The base url for the remote repository. e.g.
  "https://github.com/username/". This will be used with the package name to set the url
  for the remote repository, as well as to determine the account's username. Failing to
  specify this will cause an error. This is case-sensitive for some plugins, so take care
  to enter it correctly.
* `license::Union{AbstractString, Void}=nothing`: Name of the package licsense. If
  no license is specified, no license is created. `show_license` can be used to list all
  available licenses, or to print out a particular license's text.
* `authors::Union{AbstractString, Array}=LibGit2.getconfig("user.name", "")`: Names that
  appear on the license. Supply a string for one author, and an array for multiple.
* `years::Union{AbstractString, Array}=string(Dates.year(Dates.today()))`: Copyright years
  on the license. Can be supplied by an Int, or a string such as "2016 - 2017".
* `julia_version::VersionNumber=VERSION`: Minimum allowed Julia version.
* `git_config::Dict{String, String}=Dict{String, String}()`: Git configuration options.
* `plugins::Vector{Plugin}`: A list of `Plugin`s that the package will include.
"""
@auto_hash_equals struct Template
    remote_prefix::AbstractString
    license::Union{AbstractString, Void}
    authors::Union{AbstractString, Array}
    years::AbstractString
    path::AbstractString
    julia_version::VersionNumber
    git_config::Dict{String, String}
    plugins::Dict{DataType, Plugin}

    function Template{P <: Plugin}(;
        remote_prefix::AbstractString="",
        license::Union{AbstractString, Void}=nothing,
        authors::Union{AbstractString, Array}=LibGit2.getconfig("user.name", ""),
        years::Union{Int, AbstractString}=string(Dates.year(Dates.today())),
        julia_version::VersionNumber=VERSION,
        git_config::Dict{String, String}=Dict{String, String}(),
        plugins::Vector{P}=Vector{Plugin}(),
    )
        if isempty(remote_prefix)
            throw(ArgumentError("Must specify remote_prefix::AbstractString"))
        end
        path = Pkg.dir()
        years = string(years)
        if isa(authors, Array)
            authors = join(authors, ", ")
        end
        if !endswith(remote_prefix, "/")
            remote_prefix *= "/"
        end
        if license != nothing && !isfile(joinpath(LICENSE_DIR, license))
            throw(ArgumentError("License '$license' is not available"))
        end

        plugins = Dict{DataType, Plugin}(typeof(p) => p for p in plugins)

        new(
            remote_prefix, license, authors, years,
            path, julia_version, git_config, plugins,
        )
    end
end
