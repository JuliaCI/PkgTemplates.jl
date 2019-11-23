module PkgTemplates

using Base: active_project
using Base.Filesystem: contractuser

using Base64: base64encode
using Dates: month, today, year
import HTTP
import JSON
using JSON: json
using LibGit2: LibGit2, GitRemote, GitRepo
using Pkg: Pkg, TOML, PackageSpec
using UUIDs: uuid4

using Mustache: render
using Parameters: @with_kw_noshow

export
    Template,
    AppVeyor,
    CirrusCI,
    Citation,
    DroneCI,
    Codecov,
    Coveralls,
    Develop,
    Documenter,
    Git,
    GitHubActions,
    GitLabCI,
    License,
    ProjectFile,
    Readme,
    SrcDir,
    Tests,
    TravisCI,
    Citation,
    Online

"""
Plugins are PkgTemplates' source of customization and extensibility.
Add plugins to your [`Template`](@ref)s to enable extra pieces of repository setup.

When implementing a new plugin, subtype this type to have full control over its behaviour.
"""
abstract type Plugin end

include("template.jl")
include("plugin.jl")
include("show.jl")

# Run some function with a project activated at the given path.
function with_project(f::Function, path::AbstractString)
    proj = active_project()
    try
        Pkg.activate(path)
        f()
    finally
        proj === nothing ? Pkg.activate() : Pkg.activate(proj)
    end
end

end
