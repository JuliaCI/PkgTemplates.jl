using Base.Filesystem: path_separator

using Pkg: Pkg
using Random: Random
using Test: @test, @testset, @test_throws

using ReferenceTests: @test_reference

using PkgTemplates
const PT = PkgTemplates

const PKG = "TestPkg"
const USER = "tester"

Random.seed!(1)

tpl(; kwargs...) = Template(; user=USER, kwargs...)

@testset "PkgTemplates.jl" begin
    mktempdir() do dir
        Pkg.activate(dir)
        pushfirst!(DEPOT_PATH, dir)
        try
            include("template.jl")
            include("generate.jl")
            # include("plugin.jl")
            # include("interactive.jl")
        finally
            popfirst!(DEPOT_PATH)
        end
    end
end
