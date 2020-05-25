"""
    ProjectFile(; version=v"0.1.0")

Creates a `Project.toml`.

## Keyword Arguments
- `version::VersionNumber`: The initial version of created packages.
"""
@plugin struct ProjectFile <: Plugin
    version::VersionNumber = v"0.1.0"
end

# Other plugins like Tests will modify this file.
priority(::ProjectFile, ::typeof(hook)) = typemax(Int) - 5

function hook(p::ProjectFile, t::Template, pkg_dir::AbstractString)
    toml = Dict(
        "name" => basename(pkg_dir),
        "uuid" => string(uuid4()),
        "authors" => t.authors,
        "version" => string(p.version),
        "compat" => Dict("julia" => compat_version(t.julia)),
    )
    open(io -> TOML.print(io, toml), joinpath(pkg_dir, "Project.toml"), "w")
end

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
