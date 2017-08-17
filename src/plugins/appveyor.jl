"""
    AppVeyor(; config_file::Union{AbstractString, Void}="") -> GenericPlugin

Add `AppVeyor` to a template's plugins to add a `.appveyor.yml` configuration file to
generated repositories, and an appropriate badge to the README.

# Keyword Arguments
* `config_file::Union{AbstractString, Void}=""`: Path to a custom `.appveyor.yml`.
  If `nothing` is supplied, no file will be generated.
"""
@auto_hash_equals struct AppVeyor <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Vector{AbstractString}}
    view::Dict{String, Any}

    function AppVeyor(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "appveyor.yml")
            elseif !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            [],
            config_file,
            ".appveyor.yml",
            [
                [
                    "Build Status",
                    "https://ci.appveyor.com/api/projects/status/github/{{USER}}/{{PKGNAME}}.jl?svg=true",
                    "https://ci.appveyor.com/project/{{USER}}/{{PKGNAME}}-jl",
                ],
            ],
            Dict{String, Any}(),
        )
    end
end
