t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "CirrusCI" begin
    @testset "Plugin creation" begin
        p = CirrusCI()
        @test isempty(p.gitignore)
        @test p.src == joinpath(DEFAULTS_DIR, "cirrus.yml")
        @test p.dest == ".cirrus.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://api.cirrus-ci.com/github/{{USER}}/{{PKGNAME}}.jl.svg",
                "https://cirrus-ci.com/github/{{USER}}/{{PKGNAME}}.jl",
            ),
        ]
        @test isempty(p.view)
        p = CirrusCI(; config_file=nothing)
        @test p.src === nothing
        p = CirrusCI(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError CirrusCI(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = CirrusCI()
        @test badges(p, me, test_pkg) == ["[![Build Status](https://api.cirrus-ci.com/github/$me/$test_pkg.jl.svg)](https://cirrus-ci.com/github/$me/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        # Without a coverage plugin in the template, there should be no coverage step.
        p = CirrusCI()
        @test gen_plugin(p, t, test_pkg) == [".cirrus.yml"]
        @test isfile(joinpath(pkg_dir, ".cirrus.yml"))
        cirrus = read(joinpath(pkg_dir, ".cirrus.yml"), String)
        @test !occursin("coverage_script", cirrus)
        rm(joinpath(pkg_dir, ".cirrus.yml"))

        # Generating the plugin with Codecov in the template should create a post-test step.
        t.plugins[Codecov] = Codecov()
        gen_plugin(p, t, test_pkg)
        delete!(t.plugins, Codecov)
        cirrus = read(joinpath(pkg_dir, ".cirrus.yml"), String)
        @test occursin("coverage_script", cirrus)
        @test occursin("cirrusjl coverage", cirrus)
        rm(joinpath(pkg_dir, ".cirrus.yml"))

        p = CirrusCI(; config_file=nothing)
        @test isempty(gen_plugin(p, t, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".cirrus.yml"))
    end
end

rm(pkg_dir; recursive=true)
