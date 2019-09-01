const COVERAGE_GITIGNORE = ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]

"""
    Codecov(; file=nothing) -> Codecov

Sets up code coverage submission from CI to [Codecov](https://codecov.io).

## Keyword Arguments
- `file::Union{AbstractString, Nothing}`: Template file for `.codecov.yml`, or `nothing` to create no file.
"""
@with_kw struct Codecov <: BasicPlugin
    file::Union{String, Nothing} = nothing
end

source(p::Codecov) = p.file
destination(::Codecov) = ".codecov.yml"

badges(::Codecov) = Badge(
    "Coverage",
    "https://codecov.io/gh/{{USER}}/{{PKG}}.jl/branch/master/graph/badge.svg",
    "https://codecov.io/gh/{{USER}}/{{PKG}}.jl",
)

"""
    Coveralls(; file=nothing) -> Coverallls

Sets up code coverage submission from CI to [Coveralls](https://coveralls.io).

## Keyword Arguments
- `file::Union{AbstractString, Nothing}`: Template file for `.coveralls.yml`, or `nothing` to create no file.
"""
@with_kw struct Coveralls <: BasicPlugin
    file::Union{String, Nothing} = nothing
end

source(p::Coveralls) = p.file
destination(::Coveralls) = ".coveralls.yml"

badges(::Coveralls) = Badge(
    "Coverage",
    "https://coveralls.io/repos/github/{{USER}}/{{PKG}}.jl/badge.svg?branch=master",
    "https://coveralls.io/github/{{USER}}/{{PKG}}.jl?branch=master",
)

gitignore(::Union{Codecov, Coveralls}) = COVERAGE_GITIGNORE

"""
    is_coverage(::Type{T}) -> Bool

Determine whether or not `T` is a coverage plugin.
If you are adding a coverage plugin, you should implement this function and return `true`.
"""
is_coverage(::Type) = false
is_coverage(::Type{<:Union{Codecov, Coveralls}}) = true
