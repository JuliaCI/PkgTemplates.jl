"""
    PkgBenchmark(; file="$(contractuser(default_file("benchmark", "benchmarks.jl")))")

Sets up a [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl) benchmark suite.

You may also need to create an environment in the `benchmark` subfolder, in which you `pkg> dev` the current package.

## Keyword Arguments
- `file::AbstractString`: Template file for `benchmarks.jl`.
"""
@plugin struct PkgBenchmark <: FilePlugin
    file::String = default_file("benchmark", "benchmarks.jl")
end

source(p::PkgBenchmark) = p.file
destination(::PkgBenchmark) = joinpath("benchmark", "benchmarks.jl")
view(::PkgBenchmark, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)
