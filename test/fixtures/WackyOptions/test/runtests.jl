using WackyOptions
using Test, Aqua

@testset "WackyOptions.jl" begin
    # Write your tests here.
    @testset verbose = true "Code quality (Aqua.jl)" begin
        Aqua.test_all(WackyOptions)
    end
end
