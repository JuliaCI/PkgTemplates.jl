"""
    License(; name="MIT", path=nothing, destination="LICENSE")

Creates a license file.

## Keyword Arguments
- `name::AbstractString`: Name of a license supported by PkgTemplates.
  Available licenses can be seen [here](https://github.com/invenia/PkgTemplates.jl/tree/master/templates/licenses).
- `path::Union{AbstractString, Nothing}`: Path to a custom license file.
  This keyword takes priority over `name`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, `"LICENSE.md"` might be desired.
"""
struct License <: BasicPlugin
    path::String
    destination::String
end

function License(;
    name::AbstractString="MIT",
    path::Union{AbstractString, Nothing}=nothing,
    destination::AbstractString="LICENSE",
)
    if path === nothing
        path = default_file("licenses", name)
        isfile(path) || throw(ArgumentError("License '$(basename(path))' is not available"))
    end
    return License(path, destination)
end

source(p::License) = p.path
destination(p::License) = p.destination
view(::License, t::Template, ::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "YEAR" => year(today()),
)

function interactive(::Type{License})
    destination = prompt(String, "License: License file destination", "LICENSE")
    return if prompt(Bool, "License: Use custom license file", false)
        path = prompt(String, "License: Path to custom license file", ""; required=true)
        License(; path=path, destination=destination)
    else
        available = sort(readdir(joinpath(TEMPLATES_DIR, "licenses")))
        name = select("License: Select a license", available, "MIT")
        License(; name=name, destination=destination)
    end
end
