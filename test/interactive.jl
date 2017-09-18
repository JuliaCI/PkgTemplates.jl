# TerminalMenus.jl has issues in environments without a TTY,
# which seems to be the case in Travis CI OSX builds.
# https://travis-ci.org/invenia/PkgTemplates.jl/jobs/267682403#L115
# https://github.com/nick-paul/TerminalMenus.jl/issues/5

@testset "Interactive template creation" begin
    write(STDIN.buffer, "$me\n\n\r\n\n\n\nd")
    t = interactive_template()
    @test t.user == me
    @test t.host == "github.com"
    @test isempty(t.license)
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.years == string(Dates.year(Dates.today()))
    @test t.dir == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.requirements)
    @test isempty(t.gitconfig)
    @test isempty(t.plugins)

    if isempty(LibGit2.getconfig("github.user", ""))
        write(STDIN.buffer, "\n")
        @test_throws ArgumentError t = interactive_template()
    end

    write(STDIN.buffer, "$me\ngitlab.com\n$('\x1b')[B\r$me\n2016\n$test_file\n0.5\nX Y\nA B\n\n$('\x1b')[B\r$('\x1b')[B\rd\n\n")
    t = interactive_template()
    @test t.user == me
    @test t.host == "gitlab.com"
    # Not sure if the order the licenses are displayed in is consistent.
    @test !isempty(t.license)
    @test t.authors == me
    @test t.years == "2016"
    @test t.dir == abspath(test_file)
    @test t.julia_version == v"0.5.0"
    @test Set(t.requirements) == Set(["X", "Y"])
    @test t.gitconfig == Dict("A" => "B")
    # Like above, not sure which plugins this will generate.
    @test length(t.plugins) == 2

    write(STDIN.buffer, "$me\nd")
    t = interactive_template(; fast=true)
    @test t.user == me
    @test t.host == "github.com"
    @test t.license == "MIT"
    @test t.authors == LibGit2.getconfig("user.name", "")
    # I guess this could technically break if it runs on New Year's Eve...
    @test t.years == string(Dates.year(Dates.today()))
    @test t.dir == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.requirements)
    @test isempty(t.gitconfig)
    @test isempty(t.plugins)
    println()
end
