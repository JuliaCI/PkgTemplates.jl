using WackyOptions
using Test
using Aqua

@testset "WackyOptions.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(WackyOptions; ambiguities = false, unbound_args = true)
    end
    # Write your tests here.
end
