"""
    Codecov(; config_file::Union{AbstractString, Nothing}=nothing) -> Codecov

Add `Codecov` to a template's plugins to optionally add a `.codecov.yml` configuration file
to generated repositories, and an appropriate badge to the README. Also updates the
`.gitignore` accordingly.

# Keyword Arguments:
* `config_file::Union{AbstractString, Nothing}=nothing`: Path to a custom `.codecov.yml`.
  If left unset, no file will be generated.
"""
struct Codecov <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function Codecov(; config_file::Union{AbstractString, Nothing}=nothing)
        if config_file != nothing
            config_file = if isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"],
            config_file,
            ".codecov.yml",
            [
                Badge(
                    "Codecov",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end
Base.@deprecate_binding CodeCov Codecov

interactive(::Type{Codecov}) = interactive(Codecov; file=nothing)
