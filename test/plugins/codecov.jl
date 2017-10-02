user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "CodeCov" begin
    @testset "Plugin creation" begin
        p = CodeCov()
        @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
        @test get(p.src, "") == joinpath(PkgTemplates.DEFAULTS_DIR, "codecov.yml")
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
        @test isnull(p.src)
        p = CodeCov(; config_file=test_file)
        @test get(p.src, "") == test_file
        @test_throws ArgumentError CodeCov(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = CodeCov()
        @test badges(p, user, test_pkg) == ["[![CodeCov](https://codecov.io/gh/$user/$test_pkg.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$user/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        p = CodeCov()
        @test gen_plugin(p, t, temp_dir, test_pkg) == [".codecov.yml"]
        @test isfile(joinpath(pkg_dir, ".codecov.yml"))
        rm(joinpath(pkg_dir, ".codecov.yml"))
        p = CodeCov(; config_file=nothing)
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".codecov.yml"))
    end
end

rm(temp_dir; recursive=true)
