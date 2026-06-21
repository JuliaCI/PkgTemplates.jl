using Test
using PkgTemplates

@testset "CI Actions Versions" begin
    # 1. Check if the set of CI actions has not changed
    expected_keys = Set([
        "actions/checkout",
        "julia-actions/setup-julia",
        "actions/cache",
        "julia-actions/julia-buildpkg",
        "julia-actions/julia-runtest",
        "julia-actions/julia-processcoverage",
        "codecov/codecov-action",
        "julia-actions/cache",
        "julia-actions/julia-docdeploy",
        "julia-actions/julia-uploadcoveralls",
        "fredrikekre/runic-action"
    ])
    
    @test issetequal(keys(PkgTemplates.CI_ACTIONS), expected_keys)
    
    # 2. Check if the version of "actions/checkout" is 6 or higher
    setup_julia_val = PkgTemplates.CI_ACTIONS["actions/checkout"]
    parts = split(setup_julia_val, "@v"; limit=2)
    @test VersionNumber(parts[2]) >= v"6"
end
