"""
    CirrusCI(; config_file::Union{AbstractString, Nothing}="") -> CirrusCI

Add `CirrusCI` to a template's plugins to add a `.cirrus.yml` configuration file to
generated repositories, and an appropriate badge to the README. The default configuration
file supports only FreeBSD builds via [CirrusCI.jl](https://github.com/ararslan/CirrusCI.jl)

# Keyword Arguments
* `config_file::Union{AbstractString, Nothing}=""`: Path to a custom `.cirrus.yml`.
  If `nothing` is supplied, no file will be generated.
"""
struct CirrusCI <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function CirrusCI(; config_file::Union{AbstractString, Nothing}="")
        if config_file !== nothing
            config_file = if isempty(config_file)
                joinpath(DEFAULTS_DIR, "cirrus.yml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        return new(
            [],
            config_file,
            ".cirrus.yml",
            [
                Badge(
                    "Build Status",
                    "https://api.cirrus-ci.com/github/{{USER}}/{{PKGNAME}}.jl.svg",
                    "https://cirrus-ci.com/github/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end

interactive(::Type{CirrusCI}) = interactive(CirrusCI; file="cirrus.yml")
