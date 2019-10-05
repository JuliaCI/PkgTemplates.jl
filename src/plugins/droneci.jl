"""
    DroneCI(; config_file::Union{AbstractString, Nothing}="") -> DroneCI

Add `DroneCI` to a template's plugins to add a `.drone.yml` configuration file to
generated repositories, and an appropriate badge to the README. The default configuration
file supports Linux on ARM32 and ARM64.

# Keyword Arguments
* `config_file::Union{AbstractString, Nothing}=""`: Path to a custom `.drone.yml`.
  If `nothing` is supplied, no file will be generated.
"""
struct DroneCI <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function DroneCI(; config_file::Union{AbstractString, Nothing}="")
        if config_file !== nothing
            config_file = if isempty(config_file)
                joinpath(DEFAULTS_DIR, "drone.yml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        return new(
            [],
            config_file,
            ".drone.yml",
            [
                Badge(
                    "Build Status",
                    "https://cloud.drone.io/api/badges/{{USER}}/{{PKGNAME}}.jl/status.svg",
                    "https://cloud.drone.io/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}(),
        )
    end
end

interactive(::Type{DroneCI}) = interactive(DroneCI; file="drone.yml")
