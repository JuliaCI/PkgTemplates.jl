"""
    TravisCI(; config_file::Union{AbstractString, Void}="") -> GenericPlugin

Add `TravisCI` to a template's plugins to add a `.travis.yml` configuration file to
generated repositories, and an appropriate badge to the README.

# Keyword Arguments:
* `config_file::Union{AbstractString, Void}=""`: Path to a custom `.travis.yml`.
  If `nothing` is supplied, no file will be generated.
"""
@auto_hash_equals struct TravisCI <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Vector{AbstractString}}
    view::Dict{String, Any}

    function TravisCI(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "travis.yml")
            elseif !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            [],
            config_file,
            ".travis.yml",
            [
                [
                    "Build Status",
                    "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
                    "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl",
                ],
            ],
            Dict{String, Any}(),
        )
    end
end
