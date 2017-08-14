module PkgTemplates

using AutoHashEquals
using Mustache
using URIParser

export generate, show_license, Template, GitHubPages, AppVeyor, TravisCI, CodeCov

abstract type Plugin end

include("license.jl")
include("template.jl")
include("generate.jl")
include(joinpath("plugins", "documenter.jl"))
include(joinpath("plugins", "appveyor.jl"))
include(joinpath("plugins", "codecov.jl"))
include(joinpath("plugins", "travis.jl"))
include(joinpath("plugins", "githubpages.jl"))


const DEFAULTS_DIR = Pkg.dir("PkgTemplates", "defaults")
const LICENSE_DIR = Pkg.dir("PkgTemplates", "licenses")
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

end
