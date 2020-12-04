"""
    SrcDir(; file="$(contractuser(default_file("src", "module.jl")))")

Creates a module entrypoint.

## Keyword Arguments
- `file::AbstractString`: Template file for `src/<module>.jl`.
"""
@plugin mutable struct SrcDir <: FilePlugin
    file::String = default_file("src", "module.jl")
    destination::String = ""
end

source(p::SrcDir) = p.file
destination(p::SrcDir) = p.destination
view(::SrcDir, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

# Update the destination now that we know the package name.
# Kind of hacky, but oh well.
function prehook(p::SrcDir, t::Template, pkg_dir::AbstractString)
    p.destination = joinpath("src", basename(pkg_dir) * ".jl")
end
