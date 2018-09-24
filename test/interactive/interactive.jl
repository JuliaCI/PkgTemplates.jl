# TerminalMenus.jl has issues in environments without a TTY,
# which seems to be the case in Travis CI OSX builds.
# https://travis-ci.org/invenia/PkgTemplates.jl/jobs/267682403#L115
# https://github.com/nick-paul/TerminalMenus.jl/issues/5
# This also affects any time we write to stdin.buffer, because
# IOStreams do not have that attribute.
# Therefore, we skip any interactive tests on OSX builds.

@testset "Interactive template creation" begin
    write(stdin.buffer, "$me\n\n\r\n\n\n\n\nd")
    t = interactive_template()
    @test t.user == me
    @test t.host == "github.com"
    @test isempty(t.license)
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.years == string(Dates.year(Dates.today()))
    @test t.dir == default_dir
    @test t.julia_version == VERSION
    @test !t.ssh
    @test isempty(t.requirements)
    @test isempty(t.gitconfig)
    @test isempty(t.plugins)

    if isempty(LibGit2.getconfig("github.user", ""))
        write(stdin.buffer, "\n")
        @test_throws ArgumentError t = interactive_template()
    end

    write(stdin.buffer, "$me\ngitlab.com\n$('\x1b')[B\r$me\n2016\n$test_file\n0.5\nyes\nX Y\nkey val val\nkey2 val2\n\n$('\x1b')[B\r$('\x1b')[B\rd\n\n")
    t = interactive_template()
    @test t.user == me
    @test t.host == "gitlab.com"
    # Not sure if the order the licenses are displayed in is consistent.
    @test !isempty(t.license)
    @test t.authors == me
    @test t.years == "2016"
    @test t.dir == abspath(test_file)
    @test t.julia_version == v"0.5.0"
    @test t.ssh
    @test Set(t.requirements) == Set(["X", "Y"])
    @test t.gitconfig == Dict("key" => "val val", "key2" => "val2")
    # Like above, not sure which plugins this will generate.
    @test length(t.plugins) == 2

    # TODO: What is this supposed to warn about?
    write(stdin.buffer, "$me\n\n\r\n\nA B\nA B\n\nd")
    @test_logs (:warn, r".+") match_mode=:any interactive_template()

    write(stdin.buffer, "$me\nd")
    t = interactive_template(; fast=true)
    @test t.user == me
    @test t.host == "github.com"
    @test t.license == "MIT"
    @test t.authors == LibGit2.getconfig("user.name", "")
    # I guess this could technically break if it runs on New Year's Eve...
    @test t.years == string(Dates.year(Dates.today()))
    @test t.dir == default_dir
    @test t.julia_version == VERSION
    @test !t.ssh
    @test isempty(t.requirements)
    @test isempty(t.gitconfig)
    @test isempty(t.plugins)
    println()
end

@testset "Interactive package generation" begin
    cfg = join(("$k $v" for (k, v) in gitconfig), "\n")
    write(stdin.buffer, "$me\n\n\r\n\n\n\n$cfg\n\nd")
    generate_interactive(test_pkg)
    @test isdir(joinpath(default_dir, test_pkg))
    rm(joinpath(default_dir, test_pkg); force=true, recursive=true)
end
