"""
    format_version(v::Union{VersionNumber, AbstractString}) -> String

Strip everything but the major and minor release from a `VersionNumber`.
Strings are left in their original form.
"""
format_version(v::VersionNumber) = "$(v.major).$(v.minor)"
format_version(v::AbstractString) = string(v)

const ALLOWED_FAILURES = ["nightly"]  # TODO: Update this list with new RCs.
const DEFAULT_CI_VERSIONS = map(format_version, [default_version(), VERSION, "nightly"])
const DEFAULT_CI_VERSIONS_NO_NIGHTLY = map(format_version, [default_version(), VERSION])
const EXTRA_VERSIONS_DOC = "- `extra_versions::Vector`: Extra Julia versions to test, as strings or `VersionNumber`s."

"""
    GitHubActions(;
        file="$(contractuser(default_file("github", "workflows", "CI.yml")))",
        destination="CI.yml",
        linux=true,
        osx=false,
        windows=false,
        x64=true,
        x86=false,
        coverage=true,
        extra_versions=$DEFAULT_CI_VERSIONS,
    )

Integrates your packages with [GitHub Actions](https://github.com/features/actions).

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file,
  relative to `.github/workflows`.
- `linux::Bool`: Whether or not to run builds on Linux.
- `osx::Bool`: Whether or not to run builds on OSX (MacOS).
- `windows::Bool`: Whether or not to run builds on Windows.
- `x64::Bool`: Whether or not to run builds on 64-bit architecture.
- `x86::Bool`: Whether or not to run builds on 32-bit architecture.
- `coverage::Bool`: Whether or not to publish code coverage.
  Another code coverage plugin such as [`Codecov`](@ref) must also be included.
$EXTRA_VERSIONS_DOC

!!! note
    If using coverage plugins, don't forget to manually add your API tokens as secrets,
    as described [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets#creating-encrypted-secrets).
"""
@plugin struct GitHubActions <: FilePlugin
    file::String = default_file("github", "workflows", "CI.yml")
    destination::String = "CI.yml"
    linux::Bool = true
    osx::Bool = false
    windows::Bool = false
    x64::Bool = true
    x86::Bool = false
    coverage::Bool = true
    extra_versions::Vector = DEFAULT_CI_VERSIONS
end

source(p::GitHubActions) = p.file
destination(p::GitHubActions) = joinpath(".github", "workflows", p.destination)
tags(::GitHubActions) = "<<", ">>"

badges(::GitHubActions) = Badge(
    "Build Status",
    "https://github.com/{{{USER}}}/{{{PKG}}}.jl/workflows/CI/badge.svg",
    "https://github.com/{{{USER}}}/{{{PKG}}}.jl/actions",
)

function view(p::GitHubActions, t::Template, pkg::AbstractString)
    os = String[]
    p.linux && push!(os, "ubuntu-latest")
    p.osx && push!(os, "macOS-latest")
    p.windows && push!(os, "windows-latest")
    arch = filter(a -> getfield(p, Symbol(a)), ["x64", "x86"])
    excludes = Dict{String, String}[]
    p.osx && p.x86 && push!(excludes, Dict("E_OS" => "macOS-latest", "E_ARCH" => "x86"))

    return Dict(
        "ARCH" => arch,
        "EXCLUDES" => excludes,
        "HAS_CODECOV" => p.coverage && hasplugin(t, Codecov),
        "HAS_COVERALLS" => p.coverage && hasplugin(t, Coveralls),
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{GitHubActions}),
        "HAS_EXCLUDES" => !isempty(excludes),
        "OS" => os,
        "PKG" => pkg,
        "USER" => t.user,
        "VERSIONS" => collect_versions(t, p.extra_versions),
    )
end

"""
    TravisCI(;
        file="$(contractuser(default_file("travis.yml")))",
        linux=true,
        osx=false,
        windows=false,
        x64=true,
        x86=false,
        arm64=false,
        coverage=true,
        extra_versions=$DEFAULT_CI_VERSIONS,
    )

Integrates your packages with [Travis CI](https://travis-ci.com).

## Keyword Arguments
- `file::AbstractString`: Template file for `.travis.yml`.
- `linux::Bool`: Whether or not to run builds on Linux.
- `osx::Bool`: Whether or not to run builds on OSX (MacOS).
- `windows::Bool`: Whether or not to run builds on Windows.
- `x64::Bool`: Whether or not to run builds on 64-bit architecture.
- `x86::Bool`: Whether or not to run builds on 32-bit architecture.
- `arm64::Bool`: Whether or not to run builds on the ARM64 architecture.
- `coverage::Bool`: Whether or not to publish code coverage.
  Another code coverage plugin such as [`Codecov`](@ref) must also be included.
$EXTRA_VERSIONS_DOC
"""
@plugin struct TravisCI <: FilePlugin
    file::String = default_file("travis.yml")
    linux::Bool = true
    osx::Bool = false
    windows::Bool = false
    x64::Bool = true
    x86::Bool = false
    arm64::Bool = false
    coverage::Bool = true
    extra_versions::Vector = DEFAULT_CI_VERSIONS
end

source(p::TravisCI) = p.file
destination(::TravisCI) = ".travis.yml"

badges(::TravisCI) = Badge(
    "Build Status",
    "https://travis-ci.com/{{{USER}}}/{{{PKG}}}.jl.svg?branch={{{BRANCH}}}",
    "https://travis-ci.com/{{{USER}}}/{{{PKG}}}.jl",
)

function view(p::TravisCI, t::Template, pkg::AbstractString)
    os = filter(o -> getfield(p, Symbol(o)), ["linux", "osx", "windows"])
    arch = filter(a -> getfield(p, Symbol(a)), ["x64", "x86", "arm64"])
    versions = collect_versions(t, p.extra_versions)
    allow_failures = filter(in(versions), ALLOWED_FAILURES)

    excludes = Dict{String, String}[]
    p.x86 && p.osx && push!(excludes, Dict("E_OS" => "osx", "E_ARCH" => "x86"))
    if p.arm64
        p.osx && push!(excludes, Dict("E_OS" => "osx", "E_ARCH" => "arm64"))
        p.windows && push!(excludes, Dict("E_OS" => "windows", "E_ARCH" => "arm64"))
        "nightly" in versions && push!(excludes, Dict("E_JULIA" => "nightly", "E_ARCH" => "arm64"))
    end

    return Dict(
        "ALLOW_FAILURES" => allow_failures,
        "ARCH" => arch,
        "BRANCH" => something(default_branch(t), DEFAULT_DEFAULT_BRANCH),
        "EXCLUDES" => excludes,
        "HAS_ALLOW_FAILURES" => !isempty(allow_failures),
        "HAS_CODECOV" => hasplugin(t, Codecov),
        "HAS_COVERAGE" => p.coverage && hasplugin(t, is_coverage),
        "HAS_COVERALLS" => hasplugin(t, Coveralls),
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{TravisCI}),
        "HAS_EXCLUDES" => !isempty(excludes),
        "OS" => os,
        "PKG" => pkg,
        "USER" => t.user,
        "VERSION" => format_version(t.julia),
        "VERSIONS" => versions,
    )
end

"""
    AppVeyor(;
        file="$(contractuser(default_file("appveyor.yml")))",
        x86=false,
        coverage=true,
        extra_versions=$DEFAULT_CI_VERSIONS,
    )

Integrates your packages with [AppVeyor](https://appveyor.com)
via [AppVeyor.jl](https://github.com/JuliaCI/Appveyor.jl).

## Keyword Arguments
- `file::AbstractString`: Template file for `.appveyor.yml`.
- `x86::Bool`: Whether or not to run builds on 32-bit systems,
  in addition to the default 64-bit builds.
- `coverage::Bool`: Whether or not to publish code coverage.
  [`Codecov`](@ref) must also be included.
$EXTRA_VERSIONS_DOC
"""
@plugin struct AppVeyor <: FilePlugin
    file::String = default_file("appveyor.yml")
    x86::Bool = false
    coverage::Bool = true
    extra_versions::Vector = DEFAULT_CI_VERSIONS
end

source(p::AppVeyor) = p.file
destination(::AppVeyor) = ".appveyor.yml"

badges(::AppVeyor) = Badge(
    "Build Status",
    "https://ci.appveyor.com/api/projects/status/github/{{{USER}}}/{{{PKG}}}.jl?svg=true",
    "https://ci.appveyor.com/project/{{{USER}}}/{{{PKG}}}-jl",
)

function view(p::AppVeyor, t::Template, pkg::AbstractString)
    platforms = ["x64"]
    p.x86 && push!(platforms, "x86")

    versions = collect_versions(t, p.extra_versions)
    allow_failures = filter(in(versions), ALLOWED_FAILURES)

    return Dict(
        "ALLOW_FAILURES" => allow_failures,
        "BRANCH" => something(default_branch(t), DEFAULT_DEFAULT_BRANCH),
        "HAS_ALLOW_FAILURES" => !isempty(allow_failures),
        "HAS_CODECOV" => p.coverage && hasplugin(t, Codecov),
        "PKG" => pkg,
        "PLATFORMS" => platforms,
        "USER" => t.user,
        "VERSIONS" => versions,
    )
end

"""
    CirrusCI(;
        file="$(contractuser(default_file("cirrus.yml")))",
        image="freebsd-12-0-release-amd64",
        coverage=true,
        extra_versions=$DEFAULT_CI_VERSIONS,
    )

Integrates your packages with [Cirrus CI](https://cirrus-ci.org)
via [CirrusCI.jl](https://github.com/ararslan/CirrusCI.jl).

## Keyword Arguments
- `file::AbstractString`: Template file for `.cirrus.yml`.
- `image::AbstractString`: The FreeBSD image to be used.
- `coverage::Bool`: Whether or not to publish code coverage.
  [`Codecov`](@ref) must also be included.
$EXTRA_VERSIONS_DOC

!!! note
    Code coverage submission from Cirrus CI is not yet supported by
    [Coverage.jl](https://github.com/JuliaCI/Coverage.jl).
"""
@plugin struct CirrusCI <: FilePlugin
    file::String = default_file("cirrus.yml")
    image::String = "freebsd-12-0-release-amd64"
    coverage::Bool = true
    extra_versions::Vector = DEFAULT_CI_VERSIONS
end

source(p::CirrusCI) = p.file
destination(::CirrusCI) = ".cirrus.yml"

badges(::CirrusCI) = Badge(
    "Build Status",
    "https://api.cirrus-ci.com/github/{{{USER}}}/{{{PKG}}}.jl.svg",
    "https://cirrus-ci.com/github/{{{USER}}}/{{{PKG}}}.jl",
)

function view(p::CirrusCI, t::Template, pkg::AbstractString)
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

"""
    GitLabCI(;
        file="$(contractuser(default_file("gitlab-ci.yml")))",
        coverage=true,
        extra_versions=$DEFAULT_CI_VERSIONS_NO_NIGHTLY,
    )

Integrates your packages with [GitLab CI](https://docs.gitlab.com/ce/ci).

## Keyword Arguments
- `file::AbstractString`: Template file for `.gitlab-ci.yml`.
- `coverage::Bool`: Whether or not to compute code coverage.
$EXTRA_VERSIONS_DOC

## GitLab Pages
Documentation can be generated by including a `Documenter{GitLabCI}` plugin.
See [`Documenter`](@ref) for more information.

!!! note
    Nightly Julia is not supported.
"""
@plugin struct GitLabCI <: FilePlugin
    file::String = default_file("gitlab-ci.yml")
    coverage::Bool = true
    # Nightly has no Docker image.
    extra_versions::Vector = DEFAULT_CI_VERSIONS_NO_NIGHTLY
end

gitignore(p::GitLabCI) = p.coverage ? COVERAGE_GITIGNORE : String[]
source(p::GitLabCI) = p.file
destination(::GitLabCI) = ".gitlab-ci.yml"

function badges(p::GitLabCI)
    ci = Badge(
        "Build Status",
        "https://{{{HOST}}}/{{{USER}}}/{{{PKG}}}.jl/badges/{{{BRANCH}}}/pipeline.svg",
        "https://{{{HOST}}}/{{{USER}}}/{{{PKG}}}.jl/pipelines",
    )
    cov = Badge(
        "Coverage",
        "https://{{{HOST}}}/{{{USER}}}/{{{PKG}}}.jl/badges/{{{BRANCH}}}/coverage.svg",
        "https://{{{HOST}}}/{{{USER}}}/{{{PKG}}}.jl/commits/{{{BRANCH}}}",
    )
    return p.coverage ? [ci, cov] : [ci]
end

function view(p::GitLabCI, t::Template, pkg::AbstractString)
    return Dict(
        "BRANCH" => something(default_branch(t), DEFAULT_DEFAULT_BRANCH),
        "HAS_COVERAGE" => p.coverage,
        "HAS_DOCUMENTER" => hasplugin(t, Documenter{GitLabCI}),
        "HOST" => t.host,
        "PKG" => pkg,
        "USER" => t.user,
        "VERSION" => format_version(t.julia),
        "VERSIONS" => collect_versions(t, p.extra_versions),
    )
end

"""
    DroneCI(;
        file="$(contractuser(default_file("drone.star")))",
        amd64=true,
        arm=false,
        arm64=false,
        extra_versions=$DEFAULT_CI_VERSIONS_NO_NIGHTLY,
    )

Integrates your packages with [Drone CI](https://drone.io).

## Keyword Arguments
- `file::AbstractString`: Template file for `.drone.star`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, you might want to generate a `.drone.yml` instead of the default Starlark file.
- `amd64::Bool`: Whether or not to run builds on AMD64.
- `arm::Bool`: Whether or not to run builds on ARM (32-bit).
- `arm64::Bool`: Whether or not to run builds on ARM64.
$EXTRA_VERSIONS_DOC

!!! note
    Nightly Julia is not supported.
"""
@plugin struct DroneCI <: FilePlugin
    file::String = default_file("drone.star")
    destination::String = ".drone.star"
    amd64::Bool = true
    arm::Bool = false
    arm64::Bool = false
    extra_versions::Vector = DEFAULT_CI_VERSIONS_NO_NIGHTLY
end

source(p::DroneCI) = p.file
destination(p::DroneCI) = p.destination

badges(::DroneCI) = Badge(
    "Build Status",
    "https://cloud.drone.io/api/badges/{{{USER}}}/{{{PKG}}}.jl/status.svg",
    "https://cloud.drone.io/{{{USER}}}/{{{PKG}}}.jl",
)

function view(p::DroneCI, t::Template, pkg::AbstractString)
    arches = String[]
    p.amd64 && push!(arches, "amd64")
    p.arm && push!(arches, "arm")
    p.arm64 && push!(arches, "arm64")

    return Dict(
        "ARCHES" => join(map(repr, arches), ", "),
        "PKG" => pkg,
        "USER" => t.user,
        "VERSIONS" => join(map(repr, collect_versions(t, p.extra_versions)), ", "),
    )
end

"""
    collect_versions(t::Template, versions::Vector) -> Vector{String}

Combine `t`'s Julia version with `versions`, and format them as `major.minor`.
This is useful for creating lists of versions to be included in CI configurations.
"""
function collect_versions(t::Template, versions::Vector)
    custom = map(v -> v isa VersionNumber ? format_version(v) : string(v), versions)
    vs = map(v -> lstrip(v, 'v'), [format_version(t.julia); custom])
    filter!(vs) do v
        # Throw away any versions lower than the template's minimum.
        try
            VersionNumber(v) >= t.julia
        catch e
            e isa ArgumentError || rethrow()
            true
        end
    end
    return sort(unique(vs))
end

const AllCI = Union{AppVeyor, GitHubActions, TravisCI, CirrusCI, GitLabCI, DroneCI}

"""
    is_ci(::Plugin) -> Bool

Determine whether or not a plugin is a CI plugin.
If you are adding a CI plugin, you should implement this function and return `true`.
"""
is_ci(::Plugin) = false
is_ci(::AllCI) = true

needs_username(::AllCI) = true
customizable(::Type{<:AllCI}) = (:extra_versions => Vector{String},)
