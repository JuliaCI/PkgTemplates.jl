user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

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
        @test badges(p, user, test_pkg) == ["[![Build Status](https://ci.appveyor.com/api/projects/status/github/$user/$test_pkg.jl?svg=true)](https://ci.appveyor.com/project/$user/$test_pkg-jl)"]
    end

    @testset "File generation" begin
        p = AppVeyor()
        @test gen_plugin(p, t, temp_dir, test_pkg) == [".appveyor.yml"]
        @test isfile(joinpath(pkg_dir, ".appveyor.yml"))
        appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
        @test !contains(appveyor, "coverage=true")
        @test !contains(appveyor, "after_test")
        @test !contains(appveyor, "Codecov.submit")
        @test !contains(appveyor, "Coveralls.submit")
        rm(joinpath(pkg_dir, ".appveyor.yml"))
        t.plugins[CodeCov] = CodeCov()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, CodeCov)
        appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
        @test contains(appveyor, "coverage=true")
        @test contains(appveyor, "after_test")
        @test contains(appveyor, "Codecov.submit")
        @test !contains(appveyor, "Coveralls.submit")
        rm(joinpath(pkg_dir, ".appveyor.yml"))
        t.plugins[Coveralls] = Coveralls()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, Coveralls)
        appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
        @test contains(appveyor, "coverage=true")
        @test contains(appveyor, "after_test")
        @test contains(appveyor, "Coveralls.submit")
        @test !contains(appveyor, "Codecov.submit")
        rm(joinpath(pkg_dir, ".appveyor.yml"))
        p = AppVeyor(; config_file=nothing)
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".appveyor.yml"))
    end
end

rm(temp_dir; recursive=true)
