t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "TravisCI" begin
    @testset "Plugin creation" begin
        p = TravisCI()
        @test isempty(p.gitignore)
        @test p.src == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
        @test p.dest == ".travis.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://travis-ci.com/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
                "https://travis-ci.com/{{USER}}/{{PKGNAME}}.jl",
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
        @test badges(p, me, test_pkg) == ["[![Build Status](https://travis-ci.com/$me/$test_pkg.jl.svg?branch=master)](https://travis-ci.com/$me/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        # Without a coverage plugin in the template, there should be no post-test step.
        p = TravisCI()
        @test gen_plugin(p, t, test_pkg) == [".travis.yml"]
        @test isfile(joinpath(pkg_dir, ".travis.yml"))
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)

        @test !occursin("after_success", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        @test !occursin("stage: Documentation", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))

        # Generating the plugin with Codecov in the template should create a post-test step.
        t.plugins[Codecov] = Codecov()
        gen_plugin(p, t, test_pkg)
        delete!(t.plugins, Codecov)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        @test !occursin("stage: Documentation", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))

        # Coveralls should do the same.
        t.plugins[Coveralls] = Coveralls()
        gen_plugin(p, t, test_pkg)
        delete!(t.plugins, Coveralls)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("Coveralls.submit", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("stage: Documentation", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))

        # With a Documenter plugin, there should be a docs deployment step.
        t.plugins[GitHubPages] = GitHubPages()
        gen_plugin(p, t, test_pkg)
        delete!(t.plugins, GitHubPages)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("stage: Documentation", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))

        p = TravisCI(; config_file=nothing)
        @test isempty(gen_plugin(p, t, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".travis.yml"))
    end
end

rm(pkg_dir; recursive=true)
