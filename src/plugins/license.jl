"""
    License(; name="MIT", path=nothing, destination="LICENSE")

Creates a license file.

## Keyword Arguments
- `name::AbstractString`: Name of a license supported by PkgTemplates.
  Available licenses can be seen
  [here](https://github.com/JuliaCI/PkgTemplates.jl/tree/master/templates/licenses).
- `path::Union{AbstractString, Nothing}`: Path to a custom license file.
  This keyword takes priority over `name`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, `"LICENSE.md"` might be desired.
"""
struct License <: FilePlugin
    path::String
    destination::String
end

const LICENSE_ALIASES = Dict(
    # Legacy names kept for backward compatibility; prefer SPDX identifiers.
    "ASL" => "Apache-2.0",
    "BSD2" => "BSD-2-Clause",
    "BSD3" => "BSD-3-Clause",
    "MPL" => "MPL-2.0",
    "EUPL-1.2+" => "EUPL-1.2",
    "AGPL-3.0+" => "AGPL-3.0-or-later",
    "GPL-2.0+" => "GPL-2.0-or-later",
    "GPL-3.0+" => "GPL-3.0-or-later",
    "LGPL-2.1+" => "LGPL-2.1-or-later",
    "LGPL-3.0+" => "LGPL-3.0-or-later",
)

function License(;
    name::AbstractString="MIT",
    path::Union{AbstractString, Nothing}=nothing,
    destination::AbstractString="LICENSE",
)
    if path === nothing
        if haskey(LICENSE_ALIASES, name)
            new = LICENSE_ALIASES[name]
            Base.depwarn("License name \"$name\" is deprecated; use \"$new\" instead.", :License)
            name = new
        end
        path = default_file("licenses", name)
        isfile(path) || throw(ArgumentError("License '$(basename(path))' is not available"))
    end
    return License(path, destination)
end

defaultkw(::Type{License}, ::Val{:path}) = nothing
defaultkw(::Type{License}, ::Val{:name}) = "MIT"
defaultkw(::Type{License}, ::Val{:destination}) = "LICENSE"

source(p::License) = p.path
destination(p::License) = p.destination
view(::License, t::Template, ::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "YEAR" => year(today()),
)

function prompt(::Type{License}, ::Type, ::Val{:name})
    options = readdir(default_file("licenses"))
    # Move MIT to the top.
    deleteat!(options, findfirst(==("MIT"), options))
    pushfirst!(options, "MIT")
    menu = RadioMenu(map(license_display_name, options); pagesize=length(options))
    println("Select a license (abbreviation - full name):")
    idx = request(menu)
    return options[idx]
end

customizable(::Type{License}) = (:name => String,)

function license_display_name(name::AbstractString)
    full_name = get(LICENSE_NAMES, name, name)
    return full_name == name ? name : "$(name) - $(full_name)"
end

const LICENSE_NAMES = Dict(
    "AGPL-3.0+" => "GNU Affero General Public License v3.0 or later",
    "ASL" => "Apache License 2.0",
    "BSD2" => "BSD 2-Clause License",
    "BSD3" => "BSD 3-Clause License",
    "EUPL-1.2+" => "European Union Public Licence 1.2 or later",
    "GPL-2.0+" => "GNU General Public License v2.0 or later",
    "GPL-3.0+" => "GNU General Public License v3.0 or later",
    "ISC" => "ISC License",
    "LGPL-2.1+" => "GNU Lesser General Public License v2.1 or later",
    "LGPL-3.0+" => "GNU Lesser General Public License v3.0 or later",
    "MIT" => "MIT License",
    "MPL" => "Mozilla Public License 2.0",
)
