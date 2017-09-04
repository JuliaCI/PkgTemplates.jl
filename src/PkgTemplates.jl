__precompile__()
module PkgTemplates

using AutoHashEquals
using Mustache
using TerminalMenus
using URIParser

export generate, interactive_template, show_license, available_licenses, Template,
    GitHubPages, AppVeyor, TravisCI, GitLabCI, CodeCov, Coveralls

abstract type Plugin end

include("licenses.jl")
include("template.jl")
include("generate.jl")
include("plugin.jl")
include(joinpath("plugins", "documenter.jl"))
include(joinpath("plugins", "coveralls.jl"))
include(joinpath("plugins", "appveyor.jl"))
include(joinpath("plugins", "codecov.jl"))
include(joinpath("plugins", "travisci.jl"))
include(joinpath("plugins", "gitlabci.jl"))
include(joinpath("plugins", "githubpages.jl"))

const DEFAULTS_DIR = normpath(joinpath(@__DIR__, "..", "defaults"))
const BADGE_ORDER = [GitHubPages, TravisCI, AppVeyor, GitLabCI, CodeCov, Coveralls]

end
