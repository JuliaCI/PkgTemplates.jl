# TODO: Update the allowed failures as new versions come out.
const VersionsOrStrings = Vector{Union{VersionNumber, String}}
const ALLOWED_FAILURES = ["1.3", "nightly"]
const DEFAULT_CI_VERSIONS = VersionsOrStrings([VERSION, "1.0", "nightly"])

format_version(v::VersionNumber) = "$(v.major).$(v.minor)"
format_version(v::AbstractString) = string(v)

function collect_versions(t::Template, versions::Vector)
    vs = [format_version(t.julia_version); map(format_version, versions)]
    return unique!(sort!(vs))
end

@with_kw struct TravisCI <: BasicPlugin
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

function view(p::TravisCI, t::Template, pkg::AbstractString)
    os = String[]
    p.linux && push!(os, "linux")
    p.osx && push!(os, "osx")
    p.windows && push!(os, "windows")


    versions = collect_versions(t, p.extra_versions)
    allow_failures = filter(in(versions), ALLOWED_FAILURES)

    x86 = Dict{String, String}[]
    if p.x86
        foreach(versions) do v
            p.linux && push!(x86, Dict("JULIA" => v, "OS" => "linux", "ARCH" => "x86"))
            p.windows && push!(x86, Dict("JULIA" => v, "OS" => "windows", "ARCH" => "x86"))
        end
    end

    return Dict(
        "ALLOW_FAILURES" => allow_failures,
        "HAS_ALLOW_FAILURES" => !isempty(allow_failures),
        "HAS_CODECOV" => hasplugin(t, Codecov),
        "HAS_COVERAGE" => p.coverage && hasplugin(t, is_coverage),
        "HAS_COVERALLS" => hasplugin(t, Coveralls),
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{TravisCI}),
        "HAS_JOBS" => p.x86 || hasplugin(t, Documenter{TravisCI}),
        "OS" => os,
        "PKG" => pkg,
        "USER" => t.user,
        "VERSION" => format_version(t.julia_version),
        "VERSIONS" => versions,
        "X86" => x86,
    )
end

@with_kw struct AppVeyor <: BasicPlugin
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

function view(p::AppVeyor, t::Template, pkg::AbstractString)
    platforms = ["x64"]
    p.x86 && push!(platforms, "x86")

    versions = collect_versions(t, p.extra_versions)
    allow_failures = filter(in(versions), ALLOWED_FAILURES)

    return Dict(
        "ALLOW_FAILURES" => allow_failures,
        "HAS_ALLOW_FAILURES" => !isempty(allow_failures),
        "HAS_CODECOV" => p.coverage && hasplugin(t, Codecov),
        "PKG" => pkg,
        "PLATFORMS" => platforms,
        "USER" => t.user,
        "VERSIONS" => versions,
    )
end

@with_kw struct CirrusCI <: BasicPlugin
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
        "HAS_COVERAGE" => p.coverage && hasplugin(t, is_coverage),
        "IMAGE" => p.image,
        "PKG" => pkg,
        "USER" => t.user,
        "VERSIONS" => collect_versions(t, p.extra_versions),
    )
end

@with_kw struct GitLabCI <: BasicPlugin
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
        "USER" => t.user,
        "VERSION" => format_version(t.julia_version),
        "VERSIONS" => collect_versions(t, p.extra_versions),
    )
end

is_ci(::Type) = false
is_ci(::Type{<:Union{AppVeyor, TravisCI, CirrusCI, GitLabCI}}) = true
