"""
    Benchmarks(; file="$(contractuser(default_file("benchmark", "benchmarks.jl")))")

Sets up BenchmarkTools for packages.

## Keyword Arguments
- `file::AbstractString`: Template file for `benchmarks.jl`.
"""
@plugin struct Benchmarks <: FilePlugin
    file::String = default_file("benchmark", "benchmarks.jl")
end

source(p::Benchmarks) = p.file
destination(::Benchmarks) = joinpath("benchmark", "benchmarks.jl")
view(::Benchmarks, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)
