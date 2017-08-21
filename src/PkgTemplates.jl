module PkgTemplates

using AutoHashEquals
using Mustache
using TerminalMenus
using URIParser

export generate, interactive_template, show_license, Template, GitHubPages, AppVeyor,
    TravisCI, CodeCov, Coveralls

abstract type Plugin end

include("license.jl")
include("template.jl")
include("generate.jl")
include("plugin.jl")
include(joinpath("plugins", "documenter.jl"))
include(joinpath("plugins", "coveralls.jl"))
include(joinpath("plugins", "appveyor.jl"))
include(joinpath("plugins", "codecov.jl"))
include(joinpath("plugins", "travisci.jl"))
include(joinpath("plugins", "githubpages.jl"))

const DEFAULTS_DIR = normpath(joinpath(@__DIR__, "..", "defaults"))
const LICENSE_DIR = normpath(joinpath(@__DIR__, "..", "licenses"))
const LICENSES = Dict(
    "MIT" => "MIT \"Expat\" License",
    "BSD" => "Simplified \"2-clause\" BSD License",
    "ASL" => "Apache License, Version 2.0",
    "MPL" => "Mozilla Public License, Version 2.0",
    "GPL-2.0+" => "GNU Public License, Version 2.0+",
    "GPL-3.0+" => "GNU Public License, Version 3.0+",
    "LGPL-2.1+" => "Lesser GNU Public License, Version 2.1+",
    "LGPL-3.0+" => "Lesser GNU Public License, Version 3.0+"
)
const BADGE_ORDER = [GitHubPages, TravisCI, AppVeyor, CodeCov, Coveralls]

end
