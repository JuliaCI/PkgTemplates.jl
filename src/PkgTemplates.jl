module PkgTemplates

using Base: active_project, contractuser

using Dates: month, today, year
using InteractiveUtils: subtypes
using LibGit2: LibGit2, GitConfig, GitReference, GitRemote, GitRepo, delete_branch
using Pkg: Pkg, TOML, PackageSpec
using REPL.TerminalMenus: MultiSelectMenu, RadioMenu, request
using UUIDs: uuid4

using Mustache: render
using Parameters: @with_kw_noshow

export
    Template,
    AppVeyor,
    BlueStyleBadge,
    CirrusCI,
    Citation,
    Codecov,
    ColPracBadge,
    CompatHelper,
    Coveralls,
    Develop,
    Documenter,
    DroneCI,
    Git,
    GitHubActions,
    GitLabCI,
    License,
    Logo,
    NoDeploy,
    ProjectFile,
    Readme,
    RegisterAction,
    Secret,
    SrcDir,
    TagBot,
    Tests,
    TravisCI,
    fixup

"""
Plugins are PkgTemplates' source of customization and extensibility.
Add plugins to your [`Template`](@ref)s to enable extra pieces of repository setup.

When implementing a new plugin, subtype this type to have full control over its behaviour.
"""
abstract type Plugin end

"""
    isfixable(::Plugin, pkg_dir) -> Bool

Determines whether or not the plugin can be updated on an existing project via
[`fixup`](@ref).
"""
isfixable(::Plugin, pkg_dir) = false

include("template.jl")
include("plugin.jl")
include("show.jl")
include("interactive.jl")
include("fixup.jl")
include("deprecated.jl")

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
