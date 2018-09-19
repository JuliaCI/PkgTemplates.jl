user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "GitHubPages" begin
    @testset "Plugin creation" begin
        p = GitHubPages()
        @test p.gitignore == ["/docs/build/", "/docs/site/"]
        @test isempty(p.assets)
        p = GitHubPages(; assets=[test_file])
        @test p.assets == [test_file]
        @test_throws ArgumentError GitHubPages(; assets=[fake_path])
    end

    @testset "Badge generation" begin
        p = GitHubPages()
        @test badges(p, user, test_pkg) ==  [
            "[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://$user.github.io/$test_pkg.jl/stable)"
            "[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://$user.github.io/$test_pkg.jl/latest)"
        ]
    end

    @testset "File generation" begin
        p = GitHubPages()
        @test gen_plugin(p, t, temp_dir, test_pkg) == ["docs/"]
        @test isdir(joinpath(pkg_dir, "docs"))
        @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test occursin("assets=[]", make)
        @test !occursin("deploydocs", make)
        @test isdir(joinpath(pkg_dir, "docs", "src"))
        @test isfile(joinpath(pkg_dir, "docs", "src", "index.md"))
        index = readchomp(joinpath(pkg_dir, "docs", "src", "index.md"))
        @test index == "# $test_pkg"
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        p = GitHubPages(; assets=[test_file])
        @test gen_plugin(p, t, temp_dir, test_pkg) == ["docs/"]
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test occursin(
            strip("""
            assets=[
                    "assets/$(basename(test_file))",
                ]
            """),
            make,
        )
        @test isfile(joinpath(pkg_dir, "docs", "src", "assets", basename(test_file)))
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        t.plugins[TravisCI] = TravisCI()
        @test gen_plugin(p, t, temp_dir, test_pkg) == ["docs/"]
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test occursin("deploydocs", make)
        rm(joinpath(pkg_dir, "docs"); recursive=true)
    end
end

rm(temp_dir; recursive=true)
