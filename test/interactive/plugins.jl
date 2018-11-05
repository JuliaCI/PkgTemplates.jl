# These tests are to be skipped in OSX builds, see ./interactive.jl for more info.

@testset "TravisCI" begin
    write(stdin.buffer, "\n")
    p = interactive(TravisCI)
    @test p.src == joinpath(DEFAULTS_DIR, "travis.yml")
    write(stdin.buffer, "$test_file\n")
    p = interactive(TravisCI)
    @test p.src == test_file
    write(stdin.buffer, "none\n")
    p = interactive(TravisCI)
    @test p.src === nothing
    write(stdin.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(TravisCI)
    println()
end

@testset "AppVeyor" begin
    write(stdin.buffer, "\n")
    p = interactive(AppVeyor)
    @test p.src == joinpath(DEFAULTS_DIR, "appveyor.yml")
    write(stdin.buffer, "$test_file\n")
    p = interactive(AppVeyor)
    @test p.src == test_file
    write(stdin.buffer, "none\n")
    p = interactive(AppVeyor)
    @test p.src === nothing
    write(stdin.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(AppVeyor)
    println()
end

@testset "GitLabCI" begin
    write(stdin.buffer, "\n\n")
    p = interactive(GitLabCI)
    @test p.src == joinpath(DEFAULTS_DIR, "gitlab-ci.yml")
    @test p.view == Dict("GITLABCOVERAGE" => true)
    write(stdin.buffer, "$test_file\nno\n")
    p = interactive(GitLabCI)
    @test p.src == test_file
    @test p.view == Dict("GITLABCOVERAGE" => false)
    write(stdin.buffer, "none\n\n")
    p = interactive(GitLabCI)
    @test p.src === nothing
    write(stdin.buffer, "$fake_path\n\n")
    @test_throws ArgumentError interactive(GitLabCI)
    println()
end

@testset "Codecov" begin
    write(stdin.buffer, "\n")
    p = interactive(Codecov)
    @test p.src === nothing
    write(stdin.buffer, "$test_file\n")
    p = interactive(Codecov)
    @test p.src == test_file
    write(stdin.buffer, "none\n")
    p = interactive(Codecov)
    @test p.src === nothing
    write(stdin.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(Codecov)
    println()
end

@testset "Coveralls" begin
    write(stdin.buffer, "\n")
    p = interactive(Coveralls)
    @test p.src === nothing
    write(stdin.buffer, "$test_file\n")
    p = interactive(Coveralls)
    @test p.src == test_file
    write(stdin.buffer, "none\n")
    p = interactive(Coveralls)
    @test p.src === nothing
    write(stdin.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(Coveralls)
    println()
end

@testset "GitHubPages" begin
    write(stdin.buffer, "\n")
    p = interactive(GitHubPages)
    @test isempty(p.assets)
    write(stdin.buffer, "$test_file\n")
    p = interactive(GitHubPages)
    @test p.assets == [test_file]
    write(stdin.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(GitHubPages)
    println()
end
