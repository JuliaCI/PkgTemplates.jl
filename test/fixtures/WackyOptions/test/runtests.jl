using WackyOptions
using Test
using Aqua
using JET

@testset "WackyOptions.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(WackyOptions; ambiguities = false, unbound_args = true)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(WackyOptions; target_defined_modules = true)
    end
    # Write your tests here.
end
