t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "Codecov" begin
    @testset "Plugin creation" begin
        p = Codecov()
        @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
        @test p.src === nothing
        @test p.dest == ".codecov.yml"
        @test p.badges == [
            Badge(
                "Codecov",
                "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
                "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
            )
        ]
        @test isempty(p.view)
        p = Codecov(; config_file=nothing)
        @test p.src === nothing
        p = Codecov(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError Codecov(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = Codecov()
        @test badges(p, me, test_pkg) == ["[![Codecov](https://codecov.io/gh/$me/$test_pkg.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$me/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        p = Codecov()
        @test isempty(gen_plugin(p, t, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".codecov.yml"))

        p = Codecov(; config_file=test_file)
        @test gen_plugin(p, t, test_pkg) == [".codecov.yml"]
        @test isfile(joinpath(pkg_dir, ".codecov.yml"))
    end
end

rm(pkg_dir; recursive=true)
