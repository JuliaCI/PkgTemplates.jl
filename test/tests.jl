const invenia_url = "https://github.com/invenia"
const git_config = Dict(
    "user.name" => "Tester McTestFace",
    "user.email" => "email@web.site",
)

const fake_path = joinpath(tempdir(), tempdir())
const test_file = tempname()
template_text = """
            PKGNAME: {{PKGNAME}}
            VERSION: {{VERSION}}}
            {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
            {{#CODECOV}}CodeCov{{/CODECOV}}
            {{#AFTER}}After{{/AFTER}}
            {{#OTHER}}Other{{/OTHER}}
            """
write(test_file, template_text)

@testset "Template creation" begin
    t = Template(remote_prefix=invenia_url)
    @test t.remote_prefix == "$invenia_url/"
    @test t.license == nothing
    @test t.years == string(Dates.year(Dates.today()))
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.path == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.git_config)
    @test isempty(t.plugins)

    t = Template(remote_prefix=invenia_url; license="MIT")
    @test t.license == "MIT"

    t = Template(remote_prefix=invenia_url; years=2014)
    @test t.years == "2014"
    t = Template(remote_prefix=invenia_url; years="2014-2015")
    @test t.years == "2014-2015"

    t = Template(remote_prefix=invenia_url; authors="Some Guy")
    @test t.authors == "Some Guy"
    t = Template(remote_prefix=invenia_url; authors=["Guy", "Gal"])
    @test t.authors == "Guy, Gal"

    t = Template(remote_prefix=invenia_url; path=test_file)
    @test t.path == test_file

    t = Template(remote_prefix=invenia_url; julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(remote_prefix=invenia_url; git_config=git_config)
    @test t.git_config == git_config

    t = Template(remote_prefix=invenia_url; git_config=git_config)
    @test t.authors == git_config["user.name"]

    t = Template(
        remote_prefix=invenia_url,
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov()],
    )
    @test Set(keys(t.plugins)) == Set([GitHubPages, TravisCI, AppVeyor, CodeCov])
    @test Set(values(t.plugins)) == Set([GitHubPages(), TravisCI(), AppVeyor(), CodeCov()])

    @test_warn r".*" Template(;
        remote_prefix=invenia_url,
        plugins=[TravisCI(), TravisCI()],
    )
    @test_throws ArgumentError Template()
    @test_throws ArgumentError Template(; remote_prefix=invenia_url, license="FakeLicense")
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
        remote_prefix=invenia_url,
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

@testset "Package generation" begin
    t = Template(; remote_prefix=invenia_url)
    generate("TestPkg", t)
    @test !isfile(Pkg.dir("TestPkg", "LICENSE"))
    @test isfile(Pkg.dir("TestPkg", "README.md"))
    @test isfile(Pkg.dir("TestPkg", "REQUIRE"))
    @test isfile(Pkg.dir("TestPkg", ".gitignore"))
    @test isdir(Pkg.dir("TestPkg", "src"))
    @test isfile(Pkg.dir("TestPkg", "src", "TestPkg.jl"))
    @test isdir(Pkg.dir("TestPkg", "test"))
    @test isfile(Pkg.dir("TestPkg", "test", "runtests.jl"))
    repo = LibGit2.GitRepo(Pkg.dir("TestPkg"))
    @test LibGit2.getconfig(repo, "user.name", "") == LibGit2.getconfig("user.name", "")
    branches = [LibGit2.name(branch[1]) for branch in LibGit2.GitBranchIter(repo)]
    @test in("refs/heads/master", branches)
    @test !in("refs/heads/gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir("TestPkg"); recursive=true)

    t = Template(;
        remote_prefix=invenia_url,
        license="MIT",
        git_config=git_config,
        plugins=[AppVeyor(), GitHubPages(), CodeCov(), TravisCI()],
    )

    generate("TestPkg", t)
    @test isfile(Pkg.dir("TestPkg", "LICENSE"))
    @test isfile(Pkg.dir("TestPkg", ".travis.yml"))
    @test isfile(Pkg.dir("TestPkg", ".appveyor.yml"))
    @test isfile(Pkg.dir("TestPkg", ".codecov.yml"))
    @test isdir(Pkg.dir("TestPkg", "docs"))
    @test isfile(Pkg.dir("TestPkg", "docs", "make.jl"))
    @test isdir(Pkg.dir("TestPkg", "docs", "src"))
    @test isfile(Pkg.dir("TestPkg", "docs", "src", "index.md"))
    repo = LibGit2.GitRepo(Pkg.dir("TestPkg"))
    @test LibGit2.getconfig(repo, "user.name", "") == git_config["user.name"]
    branches = [LibGit2.name(branch[1]) for branch in LibGit2.GitBranchIter(repo)]
    @test in("refs/heads/gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir("TestPkg"); recursive=true)

    mkdir(Pkg.dir("TestPkg"))
    @test_throws ArgumentError generate("TestPkg", t)
    generate("TestPkg", t; force=true)
    @test isfile(Pkg.dir("TestPkg", "README.md"))
end

@testset "Plugin generation" begin
    mktempdir() do temp_dir
        pkg_dir = joinpath(temp_dir, "TestPkg")
        t = Template(; remote_prefix=invenia_url, path=temp_dir)

        p = TravisCI()
        @test gen_plugin(p, t, "TestPkg") == [".travis.yml"]
        @test isfile(joinpath(pkg_dir, ".travis.yml"))
        rm(joinpath(pkg_dir, ".travis.yml"))
        p = TravisCI(; config_file=nothing)
        @test isempty(gen_plugin(p, t, "TestPkg"))
        @test !isfile(joinpath(pkg_dir, ".travis.yml"))
        @test_throws ArgumentError TravisCI(; config_file=fake_path)

        p = AppVeyor()
        @test gen_plugin(p, t, "TestPkg") == [".appveyor.yml"]
        @test isfile(joinpath(pkg_dir, ".appveyor.yml"))
        rm(joinpath(pkg_dir, ".appveyor.yml"))
        p = AppVeyor(; config_file=nothing)
        @test isempty(gen_plugin(p, t, "TestPkg"))
        @test !isfile(joinpath(pkg_dir, ".appveyor.yml"))
        @test_throws ArgumentError AppVeyor(; config_file=fake_path)

        p = CodeCov()
        @test gen_plugin(p, t, "TestPkg") == [".codecov.yml"]
        @test isfile(joinpath(pkg_dir, ".codecov.yml"))
        rm(joinpath(pkg_dir, ".codecov.yml"))
        p = CodeCov(; config_file=nothing)
        @test isempty(gen_plugin(p, t, "TestPkg"))
        @test !isfile(joinpath(pkg_dir, ".codecov.yml"))
        @test_throws ArgumentError CodeCov(; config_file=fake_path)

        p = GitHubPages()
        @test gen_plugin(p, t, "TestPkg") == ["docs/"]
        @test isdir(joinpath(pkg_dir, "docs"))
        @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test contains(make, "assets=[]")
        @test !contains(make, "deploydocs")
        @test isdir(joinpath(pkg_dir, "docs", "src"))
        @test isfile(joinpath(pkg_dir, "docs", "src", "index.md"))
        index = readchomp(joinpath(pkg_dir, "docs", "src", "index.md"))
        @test index == "# TestPkg"
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        p = GitHubPages(; assets=[test_file])
        @test gen_plugin(p, t, "TestPkg") == ["docs/"]
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test contains(
            make,
            strip("""
            assets=[
                    "assets/$(basename(test_file))",
                ]
            """)
        )
        @test isfile(joinpath(pkg_dir, "docs", "src", "assets", basename(test_file)))
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        t.plugins[TravisCI] = TravisCI()
        @test gen_plugin(p, t, "TestPkg") == ["docs/"]
        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test contains(make, "deploydocs")
        rm(joinpath(pkg_dir, "docs"); recursive=true)
        @test_throws ArgumentError GitHubPages(; assets=[fake_path])
    end
end

@testset "Version floor" begin
    @test version_floor(v"1.0.0") == "1.0"
    @test version_floor(v"1.0.1") == "1.0"
    @test version_floor(v"1.0.1-pre") == "1.0"
    @test version_floor(v"1.0.0-pre") == "1.0-"
end

@testset "Mustache substitution" begin
    t = Template(; remote_prefix=invenia_url)
    view = Dict{String, Any}("OTHER" => false)

    text = substitute(template_text, "TestPkg", t; view=view)
    @test contains(text, "PKGNAME: TestPkg")
    @test contains(text, "VERSION: $(t.julia_version.major).$(t.julia_version.minor)")
    @test !contains(text, "Documenter")
    @test !contains(text, "After")
    @test !contains(text, "Other")

    t.plugins[GitHubPages] = GitHubPages()
    text = substitute(template_text, "TestPkg", t; view=view)
    @test contains(text, "Documenter")
    @test contains(text, "After")
    empty!(t.plugins)

    t.plugins[CodeCov] = CodeCov()
    text = substitute(template_text, "TestPkg", t; view=view)
    @test contains(text, "CodeCov")
    @test contains(text, "After")
    empty!(t.plugins)

    view["OTHER"] = true
    text = substitute(template_text, "TestPkg", t; view=view)
    @test contains(text, "Other")
end

@testset "License display" begin
    # TODO: Figure out how to not close pipes so frequently and find out if
    # my conversion from UInt8[] to String is using the right method.
    old_stdout = STDOUT
    out_read, out_write = redirect_stdout()
    show_license()
    close(out_write)
    licenses = join([Char(c) for c in readavailable(out_read)])
    close(out_read)
    out_read, out_write = redirect_stdout()
    show_license("MIT")
    close(out_write)
    mit = join([Char(c) for c in readavailable(out_read)])
    close(out_read)
    redirect_stdout(old_stdout)

    for (short, long) in LICENSES
        @test contains(licenses, "$short: $long")
    end
    @test strip(mit) == strip(read_license("MIT"))
    @test strip(read_license("MIT")) == strip(readstring(joinpath(LICENSE_DIR, "MIT")))
    @test_throws ArgumentError read_license("FakeLicense")
end
