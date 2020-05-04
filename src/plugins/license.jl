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
struct License <: FilePlugin
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
    menu = RadioMenu(options; pagesize=length(options))
    println("Select a license:")
    idx = request(menu)
    return options[idx]
end

customizable(::Type{License}) = (:name => String,)
