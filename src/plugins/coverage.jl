const COVERAGE_GITIGNORE = ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]

"""
    Codecov(; file=nothing)

Sets up code coverage submission from CI to [Codecov](https://codecov.io).

## Keyword Arguments
- `file::Union{AbstractString, Nothing}`: Template file for `.codecov.yml`,
  or `nothing` to create no file.
"""
@plugin struct Codecov <: FilePlugin
    file::Union{String, Nothing} = nothing
end

source(p::Codecov) = p.file
destination(::Codecov) = ".codecov.yml"

badges(::Codecov) = Badge(
    "Coverage",
    "https://codecov.io/gh/{{{USER}}}/{{{PKG}}}.jl/branch/{{{BRANCH}}}/graph/badge.svg",
    "https://codecov.io/gh/{{{USER}}}/{{{PKG}}}.jl",
)

"""
    Coveralls(; file=nothing)

Sets up code coverage submission from CI to [Coveralls](https://coveralls.io).

## Keyword Arguments
- `file::Union{AbstractString, Nothing}`: Template file for `.coveralls.yml`,
  or `nothing` to create no file.
"""
@plugin struct Coveralls <: FilePlugin
    file::Union{String, Nothing} = nothing
end

source(p::Coveralls) = p.file
destination(::Coveralls) = ".coveralls.yml"

badges(::Coveralls) = Badge(
    "Coverage",
    "https://coveralls.io/repos/github/{{{USER}}}/{{{PKG}}}.jl/badge.svg?branch={{{BRANCH}}}",
    "https://coveralls.io/github/{{{USER}}}/{{{PKG}}}.jl?branch={{{BRANCH}}}",
)

gitignore(::Union{Codecov, Coveralls}) = COVERAGE_GITIGNORE
view(::Union{Codecov, Coveralls}, t::Template, pkg::AbstractString) = Dict(
    "BRANCH" => something(default_branch(t), DEFAULT_DEFAULT_BRANCH),
    "PKG" => pkg,
    "USER" => t.user,
)

"""
    is_coverage(::Plugin) -> Bool

Determine whether or not a plugin is a coverage plugin.
If you are adding a coverage plugin, you should implement this function and return `true`.
"""
is_coverage(::Plugin) = false
is_coverage(::Union{Codecov, Coveralls}) = true

needs_username(::Union{Codecov, Coveralls}) = true
