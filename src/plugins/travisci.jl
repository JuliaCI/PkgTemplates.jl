"""
    TravisCI(; config_file::Union{AbstractString, Nothing}="") -> TravisCI

Add `TravisCI` to a template's plugins to add a `.travis.yml` configuration file to
generated repositories, and an appropriate badge to the README.

# Keyword Arguments:
* `config_file::Union{AbstractString, Nothing}=""`: Path to a custom `.travis.yml`.
  If `nothing` is supplied, no file will be generated.
"""
struct TravisCI <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function TravisCI(; config_file::Union{AbstractString, Nothing}="")
        if config_file != nothing
            config_file = if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "travis.yml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            [],
            config_file,
            ".travis.yml",
            [
                Badge(
                    "Build Status",
                    "https://travis-ci.com/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
                    "https://travis-ci.com/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end

interactive(::Type{TravisCI}) = interactive(TravisCI; file="travis.yml")
