using Test
using PkgTemplates
using YAML
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

    # 3. Check collect_uses!
    fixture_ci_file = joinpath(@__DIR__, "fixtures", "ParseCI", "CI.yml")
    dict = YAML.load_file(fixture_ci_file)
    results = String[]
    PkgTemplates.ExtractCiActionsVersions.collect_uses!(dict, results)
    @test "actions/checkout@v7" in results
    @test "julia-actions/setup-julia@v3" in results
    @test "codecov/codecov-action@v7" in results

    # 4. Check extract_ci_actions_versions
    versions = PkgTemplates.ExtractCiActionsVersions.extract_ci_actions_versions([fixture_ci_file])
    @test versions["actions/checkout"] == "actions/checkout@v7"
    @test versions["julia-actions/setup-julia"] == "julia-actions/setup-julia@v3"
    @test versions["codecov/codecov-action"] == "codecov/codecov-action@v7"

end
