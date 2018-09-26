t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "CodeCov" begin
    @testset "Plugin creation" begin
        p = CodeCov()
        @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
        @test p.src === nothing
        @test p.dest == ".codecov.yml"
        @test p.badges == [
            Badge(
                "CodeCov",
                "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
                "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
            )
        ]
        @test isempty(p.view)
        p = CodeCov(; config_file=nothing)
        @test p.src === nothing
        p = CodeCov(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError CodeCov(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = CodeCov()
        @test badges(p, me, test_pkg) == ["[![CodeCov](https://codecov.io/gh/$me/$test_pkg.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$me/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        p = CodeCov()
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".codecov.yml"))
        p = CodeCov(; config_file=nothing)
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".codecov.yml"))
    end
end

rm(temp_dir; recursive=true)
