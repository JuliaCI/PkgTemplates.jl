t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "GitLabPages" begin
    @testset "Plugin creation" begin
        p = GitLabPages()
        @test p.gitignore == ["/docs/build/", "/docs/site/"]
        @test isempty(p.assets)
        p = GitLabPages(; assets=[test_file])
        @test p.assets == [test_file]
        @test_throws ArgumentError GitLabPages(; assets=[fake_path])
    end

    @testset "Badge generation" begin
        p = GitLabPages()
        @test badges(p, me, test_pkg) ==  [
            "[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://$me.gitlab.io/$test_pkg.jl/dev)"
        ]
    end

    @testset "File generation" begin
        p = GitLabPages()
        @test gen_plugin(p, t, test_pkg) == ["docs/"]
        @test isdir(joinpath(pkg_dir, "docs"))
        @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test occursin("assets=String[]", make)
        @test !occursin("deploydocs", make)
        @test isdir(joinpath(pkg_dir, "docs", "src"))
        @test isfile(joinpath(pkg_dir, "docs", "src", "index.md"))
        index = readchomp(joinpath(pkg_dir, "docs", "src", "index.md"))
        @test occursin("autodocs", index)
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        p = GitLabPages(; assets=[test_file])
        @test gen_plugin(p, t, test_pkg) == ["docs/"]
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        # Check the formatting of the assets list.
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
    end

    @testset "Package generation with GitLabPages plugin" begin
        temp_dir = mktempdir()
        t = Template(; user=me, dir=temp_dir, plugins=[GitLabCI(), GitLabPages()])
        generate(test_pkg, t; gitconfig=gitconfig)

        gitlab = read(joinpath(t.dir, test_pkg, ".gitlab-ci.yml"), String)
        @test occursin("pages:", gitlab)
    end
end

rm(pkg_dir; recursive=true)
