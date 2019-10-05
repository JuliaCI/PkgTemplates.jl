t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "DroneCI" begin
    @testset "Plugin creation" begin
        p = DroneCI()
        @test isempty(p.gitignore)
        @test p.src == joinpath(DEFAULTS_DIR, "drone.yml")
        @test p.dest == ".drone.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://cloud.drone.io/api/badges/{{USER}}/{{PKGNAME}}.jl/status.svg",
                "https://cloud.drone.io/{{USER}}/{{PKGNAME}}.jl",
            ),
        ]
        @test isempty(p.view)
        p = DroneCI(; config_file=nothing)
        @test p.src === nothing
        p = DroneCI(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError DroneCI(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = DroneCI()
        @test badges(p, me, test_pkg) == ["[![Build Status](https://cloud.drone.io/api/badges/$me/$test_pkg.jl/status.svg)](https://cloud.drone.io/$me/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        # Without a coverage plugin in the template, there should be no coverage step.
        p = DroneCI()
        @test gen_plugin(p, t, test_pkg) == [".drone.yml"]
        @test isfile(joinpath(pkg_dir, ".drone.yml"))
        drone = read(joinpath(pkg_dir, ".drone.yml"), String)
        @test !occursin("coverage_script", drone)
        rm(joinpath(pkg_dir, ".drone.yml"))
    end
end

rm(pkg_dir; recursive=true)
