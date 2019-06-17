@testset "Interactive mode" begin
    @testset "Template creation" begin
        write(stdin.buffer, "$me\n\n\r\n\n\n\n\nd")
        t = interactive_template()
        @test t.user == me
        @test t.host == "github.com"
        @test isempty(t.license)
        @test t.authors == LibGit2.getconfig("user.name", "")
        @test t.dir == default_dir
        @test t.julia_version == VERSION
        @test !t.ssh
        @test t.dev
        @test !t.manifest
        @test isempty(t.plugins)

        if isempty(LibGit2.getconfig("github.user", ""))
            write(stdin.buffer, "\n")
            @test_throws ArgumentError t = interactive_template()
        end

        down = '\x1b' * "[B"  # Down array key.
        write(stdin.buffer, "$me\ngitlab.com\n$down\r$me\n$test_file\n0.5\nyes\nno\nyes\n$down\r$down\rd\n\n")
        t = interactive_template()
        @test t.user == me
        @test t.host == "gitlab.com"
        # Not sure if the order the licenses are displayed in is consistent.
        @test !isempty(t.license)
        @test t.authors == me
        @test t.dir == abspath(test_file)
        @test t.julia_version == v"0.5.0"
        @test t.ssh
        @test !t.dev
        @test t.manifest
        # Like above, not sure which plugins this will generate.
        @test length(t.plugins) == 2

        write(stdin.buffer, "$me\nd")
        t = interactive_template(; fast=true)
        @test t.user == me
        @test t.host == "github.com"
        @test t.license == "MIT"
        @test t.authors == LibGit2.getconfig("user.name", "")
        @test t.dir == default_dir
        @test t.julia_version == VERSION
        @test !t.ssh
        @test !t.manifest
        @test isempty(t.plugins)
        println()

        # Host and SSH aren't prompted for when git is disabled.
        write(stdin.buffer, "$me\n\n\r\n\n\n\nd")
        t = interactive_template(; git=false)
        @test t.host == "github.com"
        @test !t.ssh
        println()
    end

    @testset "Package generation" begin
        write(stdin.buffer, "$me\n\n\r\n\n\n\n\n\n\n\nd")
        generate_interactive(test_pkg; gitconfig=gitconfig)
        @test isdir(joinpath(default_dir, test_pkg))
        rm(joinpath(default_dir, test_pkg); force=true, recursive=true)
    end

    @testset "Plugins" begin
        include("plugins.jl")
    end
end
