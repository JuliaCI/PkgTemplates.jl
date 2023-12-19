"""
    ProjectFile(; version=v"1.0.0-DEV")

Creates a `Project.toml`.

## Keyword Arguments
- `version::VersionNumber`: The initial version of created packages.
"""
@plugin struct ProjectFile <: Plugin
    version::VersionNumber = v"1.0.0-DEV"
end

# Other plugins like Tests will modify this file.
priority(::ProjectFile, ::typeof(hook)) = typemax(Int) - 5

function hook(p::ProjectFile, t::Template, pkg_dir::AbstractString)
    toml = Dict(
        "name" => pkg_name(pkg_dir),
        "uuid" => string(@mock uuid4()),
        "authors" => t.authors,
        "version" => string(p.version),
        "compat" => Dict("julia" => compat_version(t.julia)),
    )
    write_project(joinpath(pkg_dir, "Project.toml"), toml)
end

# Taken from:
# https://github.com/JuliaLang/Pkg.jl/blob/v1.7.0/src/project.jl#L175-L177

function project_key_order(key::String)
    _project_key_order = ["name", "uuid", "keywords", "license", "desc", "deps", "compat"]
    return something(findfirst(x -> x == key, _project_key_order), length(_project_key_order) + 1)
end

write_project(path::AbstractString, dict) =
    open(io -> write_project(io, dict), path; write = true)
write_project(io::IO, dict) =
    TOML.print(io, dict, sorted = true, by = key -> (project_key_order(key), key))

"""
    compat_version(v::VersionNumber) -> String

Format a `VersionNumber` to exclude trailing zero components.
"""
function compat_version(v::VersionNumber)
    return if v.patch == 0 && v.minor == 0
        "$(v.major)"
    elseif v.patch == 0
        "$(v.major).$(v.minor)"
    else
        "$(v.major).$(v.minor).$(v.patch)"
    end
end
