"""
    CodeCov(; config_file::Union{AbstractString, Void}="") -> GenericPlugin

Add `CodeCov` to a template's plugins to add a `.codecov.yml` configuration file to
generated repositories, and an appropriate badge to the README. Also updates the
`.gitignore` accordingly.

# Keyword Arguments:
* `config_file::Union{AbstractString, Void}=""`: Path to a custom `.codecov.yml`.
  If `nothing` is supplied, no file will be generated.
"""
@auto_hash_equals struct CodeCov <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Vector{AbstractString}}
    view::Dict{String, Any}

    function CodeCov(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "codecov.yml")
            elseif !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"],
            config_file,
            ".codecov.yml",
            [
                [
                    "CodeCov",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
                ],
            ],
            Dict{String, Any}(),
        )
    end
end
