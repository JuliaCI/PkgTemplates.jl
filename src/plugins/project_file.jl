"""
    ProjectFile()

Creates a `Project.toml`.
"""
struct ProjectFile <: Plugin end

# Other plugins like Tests will modify this file.
priority(::ProjectFile) = typemax(Int) - DEFAULT_PRIORITY + 1

function hook(::ProjectFile, t::Template, pkg_dir::AbstractString)
    toml = Dict(
        "name" => basename(pkg_dir),
        "uuid" => string(uuid4()),
        "authors" => t.authors,
        "version" => "0.1.0",
        "compat" => Dict("julia" => compat_version(t.julia_version)),
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
