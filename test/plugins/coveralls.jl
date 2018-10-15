t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "Coveralls" begin
    @testset "Plugin creation" begin
        p = Coveralls()
        @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
        @test p.src === nothing
        @test p.dest == ".coveralls.yml"
        @test p.badges == [
            Badge(
                "Coveralls",
                "https://coveralls.io/repos/github/{{USER}}/{{PKGNAME}}.jl/badge.svg?branch=master",
                "https://coveralls.io/github/{{USER}}/{{PKGNAME}}.jl?branch=master",
            )
        ]
        @test isempty(p.view)
        p = Coveralls(; config_file=nothing)
        @test p.src === nothing
        p = Coveralls(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError Coveralls(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = Coveralls()
        @test badges(p, me, test_pkg) == ["[![Coveralls](https://coveralls.io/repos/github/$me/$test_pkg.jl/badge.svg?branch=master)](https://coveralls.io/github/$me/$test_pkg.jl?branch=master)"]
    end

    @testset "File generation" begin
        p = Coveralls()
        @test isempty(gen_plugin(p, t, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".coveralls.yml"))
        p = Coveralls(; config_file=test_file)
        @test gen_plugin(p, t, test_pkg) == [".coveralls.yml"]
        @test isfile(joinpath(pkg_dir, ".coveralls.yml"))
    end
end

rm(pkg_dir; recursive=true)
