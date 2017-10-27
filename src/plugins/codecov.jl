"""
    CodeCov(; config_file::Union{AbstractString, Void}=nothing) -> CodeCov

Add `CodeCov` to a template's plugins to optionally add a `.codecov.yml` configuration file
to generated repositories, and an appropriate badge to the README. Also updates the
`.gitignore` accordingly.

# Keyword Arguments:
* `config_file::Union{AbstractString, Void}=nothing`: Path to a custom `.codecov.yml`.
  If left unset, no file will be generated.
"""
@auto_hash_equals struct CodeCov <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}

    function CodeCov(; config_file::Union{AbstractString, Void}=nothing)
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
                    "CodeCov",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
                    "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end

interactive(plugin_type::Type{CodeCov}) = interactive(plugin_type; file=nothing)
