const COVERAGE_GITIGNORE = ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]

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

is_coverage(::Type) = false
is_coverage(::Type{<:Union{Codecov, Coveralls}}) = true
