const git_config = Dict(
    "user.name" => "Tester McTestFace",
    "user.email" => "email@web.site",
)

const fake_path = joinpath("fake", "path")
const test_file = "test.file"
template_text = """
            Hello, world
            {{PKGNAME}}
            {{VERSION}}}
            {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
            {{#CODECOV}}CodeCov{{/CODECOV}}
            {{#AFTER}}After{{/AFTER}}
            {{#OTHER}}Other{{/OTHER}}
            """
write(test_file, template_text)

@testset "Template creation" begin
    t = Template(remote_prefix="https://github.com/invenia")
    @test t.remote_prefix == "https://github.com/invenia/"
    @test t.license == nothing
    @test t.years == string(Dates.year(Dates.today()))
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.path == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.git_config)
    @test isempty(t.plugins)

    t = Template(remote_prefix="https://github.com/invenia"; license="MIT")
    @test t.license == "MIT"

    t = Template(remote_prefix="https://github.com/invenia"; years=2014)
    @test t.years == "2014"
    t = Template(remote_prefix="https://github.com/invenia"; years="2014-2015")
    @test t.years == "2014-2015"

    t = Template(remote_prefix="https://github.com/invenia"; authors="Some Guy")
    @test t.authors == "Some Guy"
    t = Template(remote_prefix="https://github.com/invenia"; authors=["Guy", "Gal"])
    @test t.authors == "Guy, Gal"

    t = Template(remote_prefix="https://github.com/invenia"; path=test_file)
    @test t.path == test_file

    t = Template(remote_prefix="https://github.com/invenia"; julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(remote_prefix="https://github.com/invenia"; git_config=git_config)
    @test t.git_config == git_config

    t = Template(remote_prefix="https://github.com/invenia"; git_config=git_config)
    @test t.authors == get(git_config, "user.name", "ERROR")

    t = Template(
        remote_prefix="https://github.com/invenia",
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov()],
    )
    @test Set(keys(t.plugins)) == Set([GitHubPages, TravisCI, AppVeyor, CodeCov])
    @test Set(values(t.plugins)) == Set([GitHubPages(), TravisCI(), AppVeyor(), CodeCov()])

    @test_warn r".*" Template(;
        remote_prefix="https://github.com/invenia",
        plugins=[TravisCI(), TravisCI()],
    )

end

@testset "Plugin creation" begin
    p = AppVeyor()
    @test isempty(p.gitignore_files)
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "appveyor.yml")
    p = AppVeyor(; config_file=nothing)
    @test p.config_file == nothing
    p = AppVeyor(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError AppVeyor(; config_file=fake_path)

    p = TravisCI()
    @test isempty(p.gitignore_files)
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
    p = TravisCI(; config_file=nothing)
    @test p.config_file == nothing
    p = TravisCI(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError TravisCI(; config_file=fake_path)

    p = CodeCov()
    @test p.gitignore_files == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "codecov.yml")
    p = CodeCov(; config_file=nothing)
    @test p.config_file == nothing
    p = CodeCov(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError CodeCov(; config_file=fake_path)
end

@testset "File generation" begin
    t = Template(;
        remote_prefix="https://github.com/invenia",
        license="MPL",
        git_config=git_config,
        plugins=[TravisCI(), CodeCov(), GitHubPages(), AppVeyor()],
    )

    temp_file = tempname()
    gen_file(temp_file, "Hello, world")
    @test isfile(temp_file)
    @test readstring(temp_file) == "Hello, world\n"
    rm(temp_file)

    mktempdir() do temp_dir
        @test gen_readme(temp_dir, t) == "README.md"
        @test isfile(joinpath(temp_dir, "README.md"))
        readme = readchomp(joinpath(temp_dir, "README.md"))
        @test contains(readme, "# $(basename(temp_dir))")
        for p in values(t.plugins)
            @test contains(readme, join(badges(p, t, basename(temp_dir)), "\n"))
        end
        # Check the order of the badges.
        @test search(readme, "github.io").start <
            search(readme, "travis").start <
            search(readme, "appveyor").start <
            search(readme, "codecov").start
    end

    mktempdir() do temp_dir
        @test gen_gitignore(temp_dir, t.plugins) == ".gitignore"
        @test isfile(joinpath(temp_dir, ".gitignore"))
        gitignore = readstring(joinpath(temp_dir, ".gitignore"))
        @test contains(gitignore, ".DS_Store")
        for p in values(t.plugins)
            for entry in p.gitignore_files
                @test contains(gitignore, entry)
            end
        end
    end

    mktempdir() do temp_dir
        @test gen_license(temp_dir, t.license, t.authors, t.years) == "LICENSE"
        @test isfile(joinpath(temp_dir, "LICENSE"))
        license = readchomp(joinpath(temp_dir, "LICENSE"))
        @test contains(license, t.authors)
        @test contains(license, t.years)
        @test contains(license, read_license(t.license))
    end

    mktempdir() do temp_dir
        @test gen_entrypoint(temp_dir) == "src/"
        @test isdir(joinpath(temp_dir, "src"))
        @test isfile(joinpath(temp_dir, "src", "$(basename(temp_dir)).jl"))
        entrypoint = readchomp(joinpath(temp_dir, "src", "$(basename(temp_dir)).jl"))
        @test contains(entrypoint, "module $(basename(temp_dir))")
    end

    mktempdir() do temp_dir
        @test gen_require(temp_dir, t.julia_version) == "REQUIRE"
        @test isfile(joinpath(temp_dir, "REQUIRE"))
        vf = version_floor(t.julia_version)
        @test readchomp(joinpath(temp_dir, "REQUIRE")) == "julia $vf"
    end

    mktempdir() do temp_dir
        @test gen_tests(temp_dir) == "test/"
        @test isdir(joinpath(temp_dir, "test"))
        @test isfile(joinpath(temp_dir, "test", "runtests.jl"))
        runtests = readchomp(joinpath(temp_dir, "test", "runtests.jl"))
        @test contains(runtests, "using $(basename(temp_dir))")
        @test contains(runtests, "using Base.Test")
    end
end
