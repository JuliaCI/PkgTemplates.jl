"""
    License(; name="MIT", path=nothing, destination="LICENSE")

Creates a license file.

## Keyword Arguments
- `name::AbstractString`: Name of a license supported by PkgTemplates.
  Available licenses can be seen
  [here](https://github.com/invenia/PkgTemplates.jl/tree/master/templates/licenses).
- `path::Union{AbstractString, Nothing}`: Path to a custom license file.
  This keyword takes priority over `name`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, `"LICENSE.md"` might be desired.
"""
@plugin struct License <: FilePlugin
    name::String = "MIT"
    path::String = default_file("licenses", name)
    destination::String = "LICENSE"

    function License(name, path, destination)
        isfile(path) || throw(ArgumentError("License '$(basename(path))' is not available"))
        new(name, path, destination)
    end
end

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
    menu = RadioMenu(options; pagesize=length(options))
    println("Select a license:")
    idx = request(menu)
    return options[idx]
end

customizable(::Type{License}) = (:name => String,)
