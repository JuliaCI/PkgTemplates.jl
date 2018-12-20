"""
    AppVeyor(; config_file::Union{AbstractString, Nothing}="") -> AppVeyor

Add `AppVeyor` to a template's plugins to add a `.appveyor.yml` configuration file to
generated repositories, and an appropriate badge to the README.

# Keyword Arguments
* `config_file::Union{AbstractString, Nothing}=""`: Path to a custom `.appveyor.yml`.
  If `nothing` is supplied, no file will be generated.
"""
struct AppVeyor <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function AppVeyor(; config_file::Union{AbstractString, Nothing}="")
        if config_file != nothing
            config_file = if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "appveyor.yml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(
            [],
            config_file,
            ".appveyor.yml",
            [
                Badge(
                    "Build Status",
                    "https://ci.appveyor.com/api/projects/status/github/{{USER}}/{{PKGNAME}}.jl?svg=true",
                    "https://ci.appveyor.com/project/{{USER}}/{{PKGNAME}}-jl",
                )
            ],
            Dict{String, Any}(),
        )
    end
end
