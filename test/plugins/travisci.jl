user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "TravisCI" begin
    @testset "Plugin creation" begin
        p = TravisCI()
        @test isempty(p.gitignore)
        @test p.src == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
        @test p.dest == ".travis.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
                "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl",
            ),
        ]
        @test isempty(p.view)
        p = TravisCI(; config_file=nothing)
        @test p.src === nothing
        p = TravisCI(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError TravisCI(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = TravisCI()
        @test badges(p, user, test_pkg) == ["[![Build Status](https://travis-ci.org/$user/$test_pkg.jl.svg?branch=master)](https://travis-ci.org/$user/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        p = TravisCI()
        @test gen_plugin(p, t, temp_dir, test_pkg) == [".travis.yml"]
        @test isfile(joinpath(pkg_dir, ".travis.yml"))
        travis = readstring(joinpath(pkg_dir, ".travis.yml"))
        @test !contains(travis, "after_success")
        @test !contains(travis, "Codecov.submit")
        @test !contains(travis, "Coveralls.submit")
        @test !contains(travis, "Pkg.add(\"Documenter\")")
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[CodeCov] = CodeCov()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, CodeCov)
        travis = readstring(joinpath(pkg_dir, ".travis.yml"))
        @test contains(travis, "after_success")
        @test contains(travis, "Codecov.submit")
        @test !contains(travis, "Coveralls.submit")
        @test !contains(travis, "Pkg.add(\"Documenter\")")
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[Coveralls] = Coveralls()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, Coveralls)
        travis = readstring(joinpath(pkg_dir, ".travis.yml"))
        @test contains(travis, "after_success")
        @test contains(travis, "Coveralls.submit")
        @test !contains(travis, "Codecov.submit")
        @test !contains(travis, "Pkg.add(\"Documenter\")")
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[GitHubPages] = GitHubPages()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, GitHubPages)
        travis = readstring(joinpath(pkg_dir, ".travis.yml"))
        @test contains(travis, "after_success")
        @test contains(travis, "Pkg.add(\"Documenter\")")
        @test !contains(travis, "Codecov.submit")
        @test !contains(travis, "Coveralls.submit")
        rm(joinpath(pkg_dir, ".travis.yml"))
        p = TravisCI(; config_file=nothing)
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".travis.yml"))
    end
end

rm(temp_dir; recursive=true)
