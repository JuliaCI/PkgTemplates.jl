t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "AppVeyor" begin
    @testset "Plugin creation" begin
        p = AppVeyor()
        @test isempty(p.gitignore)
        @test p.src == joinpath(PkgTemplates.DEFAULTS_DIR, "appveyor.yml")
        @test p.dest == ".appveyor.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://ci.appveyor.com/api/projects/status/github/{{USER}}/{{PKGNAME}}.jl?svg=true",
                "https://ci.appveyor.com/project/{{USER}}/{{PKGNAME}}-jl",
            ),
        ]
        @test isempty(p.view)
        p = AppVeyor(; config_file=nothing)
        @test p.src === nothing
        p = AppVeyor(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError AppVeyor(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = AppVeyor()
        @test badges(p, me, test_pkg) == ["[![Build Status](https://ci.appveyor.com/api/projects/status/github/$me/$test_pkg.jl?svg=true)](https://ci.appveyor.com/project/$me/$test_pkg-jl)"]
    end

    @testset "File generation" begin
        # Without a coverage plugin in the template, there should be no post-test step.
        p = AppVeyor()
        @test gen_plugin(p, t, test_pkg) == [".appveyor.yml"]
        @test isfile(joinpath(pkg_dir, ".appveyor.yml"))
        appveyor = read(joinpath(pkg_dir, ".appveyor.yml"), String)
        @test !occursin("on_success", appveyor)
        @test !occursin("%JL_CODECOV_SCRIPT%", appveyor)
        rm(joinpath(pkg_dir, ".appveyor.yml"))

        # Generating the plugin with Codecov in the template should create a post-test step.
        t.plugins[Codecov] = Codecov()
        gen_plugin(p, t, test_pkg)
        delete!(t.plugins, Codecov)
        appveyor = read(joinpath(pkg_dir, ".appveyor.yml"), String)
        @test occursin("on_success", appveyor)
        @test occursin("%JL_CODECOV_SCRIPT%", appveyor)
        rm(joinpath(pkg_dir, ".appveyor.yml"))

        # TODO: Add Coveralls tests when AppVeyor.jl supports it.

        p = AppVeyor(; config_file=nothing)
        @test isempty(gen_plugin(p, t, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".appveyor.yml"))
    end
end

rm(pkg_dir; recursive=true)
