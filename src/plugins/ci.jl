const DEFAULT_CI_VERSIONS = ["1.0", "nightly"]
const VersionsOrStrings = Vector{Union{VersionNumber, String}}

format_version(v::VersionNumber) = "$(v.major).$(v.minor)"

function collect_versions(versions::Vector, t::Template)
    return unique(sort([versions; format_version(t.julia_version)]; by=string))
end

abstract type CI <: Plugin end

# TODO: A template that yields this:
# os:
#   - linux
#   - osx
#   - windows
# julia:
#   - 1.0
#   - 1.1
#   - 1.2
#   - 1.3
#   - nightly
# matrix:
#   fast_finish: true
#   allow_failures:
#     - julia: 1.3
#     - julia: nightly
#   include:
#     - os: linux
#       arch: x86
#       julia: 1.0
#     - os: windows
#       arch: x86
#       julia: 1.0
# (and maybe all the other Julia versions for 32-bit too)

@with_kw struct TravisCI <: CI
    file::String = default_file("travis.yml")
    linux::Bool = true
    osx::Bool = true
    windows::Bool = true
    x86::Bool = false
    coverage::Bool = true
    extra_versions::VersionsOrStrings = DEFAULT_CI_VERSIONS
end

source(p::TravisCI) = p.file
destination(::TravisCI) = ".travis.yml"

badges(::TravisCI) = Badge(
    "Build Status",
    "https://travis-ci.com/{{USER}}/{{PKG}}.jl.svg?branch=master",
    "https://travis-ci.com/{{USER}}/{{PKG}}.jl",
)

function view(p::TravisCI, t::Template, ::AbstractString)
    jobs = Dict{String, String}[]
    for v in collect_versions(p.extra_versions, t)
        p.linux && push!(jobs, Dict("JULIA" => v, "OS" => "linux", "ARCH" => "x64"))
        p.linux && p.x86 && push!(jobs, Dict("JULIA" => v, "OS" => "linux", "ARCH" => "x86"))
        p.osx && push!(jobs, Dict("JULIA" => v, "OS" => "osx"))
        p.windows && push!(jobs, Dict("JULIA" => v, "OS" => "windows", "ARCH" => "x64"))
        p.windows && p.x86 && push!(jobs, Dict("JULIA" => v, "OS" => "windows", "ARCH" => "x86"))
    end
    return Dict(
        "HAS_CODECOV" => hasplugin(t, Codecov),
        "HAS_COVERAGE" => p.coverage && hasplugin(t, Coverage),
        "HAS_COVERALLS" => hasplugin(t, Coveralls),
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{TravisCI}),
        "HAS_NIGHTLY" => "nightly" in versions,
        "PKG" => pkg,
        "VERSION" => format_version(t.julia_version),
    )
end

@with_kw struct AppVeyor <: CI
    file::String = default_file("appveyor.yml")
    x86::Bool = false
    coverage::Bool = true
    extra_versions::VersionsOrStrings = DEFAULT_CI_VERSIONS
end

source(p::AppVeyor) = p.file
destination(::AppVeyor) = ".appveyor.yml"

badges(::AppVeyor) = Badge(
    "Build Status",
    "https://ci.appveyor.com/api/projects/status/github/{{USER}}/{{PKG}}.jl?svg=true",
    "https://ci.appveyor.com/project/{{USER}}/{{PKG}}-jl",
)

function view(p::AppVeyor, t::Template, ::AbstractString)
    platforms = ["x64"]
    t.x86 && push!(platforms, "x86")
    return Dict(
        "HAS_CODECOV" => t.coverage && hasplugin(t, Codecov),
        "HAS_NIGHTLY" => "nightly" in versions,
        "PKG" => pkg,
        "PLATFORMS" => os,
        "VERSIONS" => collect_versions(p.extra_versions, t),
    )
end

@with_kw struct CirrusCI <: CI
    file::String = default_file("cirrus.yml")
    image::String = "freebsd-12-0-release-amd64"
    coverage::Bool = true
    extra_versions::VersionsOrStrings = DEFAULT_CI_VERSIONS
end

source(p::CirrusCI) = p.file
destination(::CirrusCI) = ".cirrus.yml"

badges(::CirrusCI) = Badge(
    "Build Status",
    "https://api.cirrus-ci.com/github/{{USER}}/{{PACKAGE}}.jl.svg",
    "https://cirrus-ci.com/github/{{USER}}/{{PKG}}.jl",
)

function view(p::CirrusCI, t::Template, ::AbstractString)
    return Dict(
        "HAS_CODECOV" => hasplugin(t, Codecov),
        "HAS_COVERALLS" => hasplugin(t, Coveralls),
        "HAS_COVERAGE" => p.coverage && hasplugin(t, Coverage),
        "IMAGE" => p.image,
        "PKG" => pkg,
        "VERSIONS" => collect_versions(p.extra_versions, t),
    )
end

@with_kw struct GitLabCI <: CI
    file::String
    documentation::Bool = true
    coverage::Bool = true
    extra_versions::Vector{VersionNumber} = [v"1.0"]
end

gitignore(p::GitLabCI) = p.coverage ? COVERAGE_GITIGNORE : String[]

source(p::GitLabCI) = p.source
destination(::GitLabCI) = ".gitlab-ci.yml"

function badges(p::GitLabCI)
    ci = Badge(
        "Build Status",
        "https://gitlab.com/{{USER}}/{{PKG}}.jl/badges/master/build.svg",
        "https://gitlab.com/{{USER}}/{{PKG}}.jl/pipelines",
    )
    cov = Badge(
        "Coverage",
        "https://gitlab.com/{{USER}}/{{PKG}}.jl/badges/master/coverage.svg",
        "https://gitlab.com/{{USER}}/{{PKG}}.jl/commits/master",
    )
    return p.coverage ? [ci, cov] : [ci]
end

function view(p::GitLabCI, t::Template, ::AbstractString)
    return Dict(
        "HAS_COVERAGE" => p.coverage,
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{GitLabCI}),
        "PKG" => pkg,
        "VERSION" => format_version(t.julia_version),
        "VERSIONS" => collect_versions(p.extra_versions, t),
    )
end
