@testset "TravisCI" begin
    write(STDIN.buffer, "\n")
    p = interactive(TravisCI)
    @test get(p.src) == joinpath(DEFAULTS_DIR, "travis.yml")
    write(STDIN.buffer, "$test_file\n")
    p = interactive(TravisCI)
    @test get(p.src) == test_file
    write(STDIN.buffer, "none\n")
    p = interactive(TravisCI)
    @test isnull(p.src)
    write(STDIN.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(TravisCI)
    println()
end

@testset "AppVeyor" begin
    write(STDIN.buffer, "\n")
    p = interactive(AppVeyor)
    @test get(p.src) == joinpath(DEFAULTS_DIR, "appveyor.yml")
    write(STDIN.buffer, "$test_file\n")
    p = interactive(AppVeyor)
    @test get(p.src) == test_file
    write(STDIN.buffer, "none\n")
    p = interactive(AppVeyor)
    @test isnull(p.src)
    write(STDIN.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(AppVeyor)
    println()
end

@testset "GitLabCI" begin
    write(STDIN.buffer, "\n\n")
    p = interactive(GitLabCI)
    @test get(p.src) == joinpath(DEFAULTS_DIR, "gitlab-ci.yml")
    @test p.view == Dict("GITLABCOVERAGE" => true)
    write(STDIN.buffer, "$test_file\nno\n")
    p = interactive(GitLabCI)
    @test get(p.src) == test_file
    @test p.view == Dict("GITLABCOVERAGE" => false)
    write(STDIN.buffer, "none\n\n")
    p = interactive(GitLabCI)
    @test isnull(p.src)
    write(STDIN.buffer, "$fake_path\n\n")
    @test_throws ArgumentError interactive(GitLabCI)
    println()
end

@testset "CodeCov" begin
    write(STDIN.buffer, "\n")
    p = interactive(CodeCov)
    @test get(p.src) == joinpath(DEFAULTS_DIR, "codecov.yml")
    write(STDIN.buffer, "$test_file\n")
    p = interactive(CodeCov)
    @test get(p.src) == test_file
    write(STDIN.buffer, "none\n")
    p = interactive(CodeCov)
    @test isnull(p.src)
    write(STDIN.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(CodeCov)
    println()
end

@testset "Coveralls" begin
    write(STDIN.buffer, "\n")
    p = interactive(Coveralls)
    @test isnull(p.src)
    write(STDIN.buffer, "$test_file\n")
    p = interactive(Coveralls)
    @test get(p.src) == test_file
    write(STDIN.buffer, "none\n")
    p = interactive(Coveralls)
    @test isnull(p.src)
    write(STDIN.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(Coveralls)
    println()
end

@testset "GitHubPages" begin
    write(STDIN.buffer, "\n")
    p = interactive(GitHubPages)
    @test isempty(p.assets)
    write(STDIN.buffer, "$test_file\n")
    p = interactive(GitHubPages)
    @test p.assets == [test_file]
    write(STDIN.buffer, "$fake_path\n")
    @test_throws ArgumentError interactive(GitHubPages)
    println()
end
