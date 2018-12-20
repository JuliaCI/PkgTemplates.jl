"""
    Coveralls(; config_file::Union{AbstractString, Nothing}=nothing) -> Coveralls

Add `Coveralls` to a template's plugins to optionally add a `.coveralls.yml` configuration
file to generated repositories, and an appropriate badge to the README. Also updates the
`.gitignore` accordingly.

# Keyword Arguments:
* `config_file::Union{AbstractString, Nothing}=nothing`: Path to a custom `.coveralls.yml`.
  If left unset, no file will be generated.
"""
struct Coveralls <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function Coveralls(; config_file::Union{AbstractString, Nothing}=nothing)
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
            ".coveralls.yml",
            [
                Badge(
                    "Coveralls",
                    "https://coveralls.io/repos/github/{{USER}}/{{PKGNAME}}.jl/badge.svg?branch=master",
                    "https://coveralls.io/github/{{USER}}/{{PKGNAME}}.jl?branch=master",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end

interactive(::Type{Coveralls}) = interactive(Coveralls; file=nothing)
