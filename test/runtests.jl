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

            # Some plugins use the current Julia version in their output,
            # and the test fixtures are generated with Julia 1.2.
            if VERSION.major == 1 && VERSION.minor == 2
                include("generate.jl")
            else
                @info "Skipping reference tests (Julia = $VERSION)"
            end
        finally
            popfirst!(DEPOT_PATH)
        end
    end
end
