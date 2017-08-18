struct Foo <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}
    Foo() = new([], @__FILE__, fake_path, [Badge("foo", "bar", "baz")], Dict{String, Any}())
end
struct Bar <: CustomPlugin end
struct Baz <: Plugin end

const git_config = Dict(
    "user.name" => "Tester McTestFace",
    "user.email" => "email@web.site",
    "github.username" => "TesterMcTestFace",
)
const test_pkg = "TestPkg"
const fake_path = bin(hash("/this/file/does/not/exist"))
const test_file = tempname()
template_text = """
            PKGNAME: {{PKGNAME}}
            VERSION: {{VERSION}}}
            {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
            {{#CODECOV}}CodeCov{{/CODECOV}}
            {{#CODECOV}}Coveralls{{/CODECOV}}
            {{#AFTER}}After{{/AFTER}}
            {{#OTHER}}Other{{/OTHER}}
            """
write(test_file, template_text)

@testset "Template creation" begin
    t = Template(; user="invenia")
    rm(t.temp_dir; recursive=true)
    @test t.user == "invenia"
    @test t.license == nothing
    @test t.years == string(Dates.year(Dates.today()))
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.dir == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.git_config)
    @test isempty(t.plugins)

    t = Template(; user="invenia", license="MIT")
    rm(t.temp_dir; recursive=true)
    @test t.license == "MIT"

    t = Template(; user="invenia", years=2014)
    rm(t.temp_dir; recursive=true)
    @test t.years == "2014"
    t = Template(user="invenia", years="2014-2015")
    rm(t.temp_dir; recursive=true)
    @test t.years == "2014-2015"

    t = Template(; user="invenia", authors="Some Guy")
    rm(t.temp_dir; recursive=true)
    @test t.authors == "Some Guy"

    t = Template(; user="invenia", authors=["Guy", "Gal"])
    rm(t.temp_dir; recursive=true)
    @test t.authors == "Guy, Gal"

    t = Template(; user="invenia", dir=test_file)
    rm(t.temp_dir; recursive=true)
    @test t.dir == test_file

    t = Template(; user="invenia", julia_version=v"0.1.2")
    rm(t.temp_dir; recursive=true)
    @test t.julia_version == v"0.1.2"

    t = Template(; user="invenia", git_config=git_config)
    rm(t.temp_dir; recursive=true)
    @test t.git_config == git_config

    t = Template(; user="invenia", git_config=git_config)
    rm(t.temp_dir; recursive=true)
    @test t.authors == git_config["user.name"]

    t = Template(; git_config=git_config)
    rm(t.temp_dir; recursive=true)
    @test t.user == git_config["github.username"]
    @test t.authors == git_config["user.name"]

    t = Template(;
        user="invenia",
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov(), Coveralls()],
    )
    rm(t.temp_dir; recursive=true)
    @test Set(keys(t.plugins)) == Set(
        [GitHubPages, TravisCI, AppVeyor, CodeCov, Coveralls]
    )
    @test Set(values(t.plugins)) == Set(
        [GitHubPages(), TravisCI(), AppVeyor(), CodeCov(), Coveralls()]
    )

    @test_warn r".+" t = Template(;
        user="invenia",
        plugins=[TravisCI(), TravisCI()],
    )
    rm(t.temp_dir; recursive=true)

    if isempty(LibGit2.getconfig("github.username", ""))
        @test_throws ArgumentError t = Template()
    else
        t = Template()
        rm(t.temp_dir; recursive=true)
        @test t.user == LibGit2.getconfig("github.username", "")
    end
    @test_throws ArgumentError t = Template(; user="invenia", license="FakeLicense")
end

@testset "Plugin creation" begin
    p = AppVeyor()
    @test isempty(p.gitignore)
    @test get(p.src) == joinpath(PkgTemplates.DEFAULTS_DIR, "appveyor.yml")
    @test p.dest == ".appveyor.yml"
    @test p.badges == [
        Badge(
            "Build Status",
            "https://ci.appveyor.com/api/projects/status/github/{{USER}}/{{PKGNAME}}.jl?svg=true",
            "https://ci.appveyor.com/project/{{USER}}/{{PKGNAME}}-jl",
        ),
    ]
    @test isempty(p.view)
    p = AppVeyor(; config_file=nothing)
    @test_throws NullException get(p.src)
    p = AppVeyor(; config_file=test_file)
    @test get(p.src) == test_file
    @test_throws ArgumentError p = AppVeyor(; config_file=fake_path)

    p = TravisCI()
    @test isempty(p.gitignore)
    @test get(p.src) == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
    @test p.dest == ".travis.yml"
    @test p.badges == [
        Badge(
            "Build Status",
            "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
            "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl",
        ),
    ]
    @test isempty(p.view)
    p = TravisCI(; config_file=nothing)
    @test_throws NullException get(p.src)
    p = TravisCI(; config_file=test_file)
    @test get(p.src) == test_file
    @test_throws ArgumentError p = TravisCI(; config_file=fake_path)

    p = CodeCov()
    @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
    @test get(p.src) == joinpath(PkgTemplates.DEFAULTS_DIR, "codecov.yml")
    @test p.dest == ".codecov.yml"
    @test p.badges == [
        Badge(
            "CodeCov",
            "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl/branch/master/graph/badge.svg",
            "https://codecov.io/gh/{{USER}}/{{PKGNAME}}.jl",
        )
    ]
    @test isempty(p.view)
    p = CodeCov(; config_file=nothing)
    @test_throws NullException get(p.src)
    p = CodeCov(; config_file=test_file)
    @test get(p.src) == test_file
    @test_throws ArgumentError p = CodeCov(; config_file=fake_path)

    p = Coveralls()
    @test p.gitignore == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
    @test_throws NullException get(p.src)
    @test p.dest == ".coveralls.yml"
    @test p.badges == [
        Badge(
            "Coveralls",
            "https://coveralls.io/repos/github/{{USER}}/{{PKGNAME}}.jl/badge.svg?branch=master",
            "https://coveralls.io/github/{{USER}}/{{PKGNAME}}.jl?branch=master",
        )
    ]
    @test isempty(p.view)
    p = Coveralls(; config_file=nothing)
    @test_throws NullException get(p.src)
    p = Coveralls(; config_file=test_file)
    @test get(p.src) == test_file
    @test_throws ArgumentError p = Coveralls(; config_file=fake_path)

    p = GitHubPages()
    @test p.gitignore == ["/docs/build/", "/docs/site/"]
    @test isempty(p.assets)
    p = GitHubPages(; assets=[test_file])
    @test p.assets == [test_file]
    @test_throws ArgumentError p = GitHubPages(; assets=[fake_path])
end

@testset "Badge generation" begin
    user = git_config["github.username"]

    badge = Badge("A", "B", "C")
    @test badge.hover == "A"
    @test badge.image == "B"
    @test badge.link == "C"
    @test format(badge) == "[![A](B)](C)"

    p = AppVeyor()
    @test badges(p, user, test_pkg) == ["[![Build Status](https://ci.appveyor.com/api/projects/status/github/$user/$test_pkg.jl?svg=true)](https://ci.appveyor.com/project/$user/$test_pkg-jl)"]

    p = TravisCI()
    @test badges(p, user, test_pkg) == ["[![Build Status](https://travis-ci.org/$user/$test_pkg.jl.svg?branch=master)](https://travis-ci.org/$user/$test_pkg.jl)"]

    p = CodeCov()
    @test badges(p, user, test_pkg) == ["[![CodeCov](https://codecov.io/gh/$user/$test_pkg.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$user/$test_pkg.jl)"]

    p = Coveralls()
    @test badges(p, user, test_pkg) == ["[![Coveralls](https://coveralls.io/repos/github/$user/$test_pkg.jl/badge.svg?branch=master)](https://coveralls.io/github/$user/$test_pkg.jl?branch=master)"]

    p = GitHubPages()
    @test badges(p, user, test_pkg) ==  [
        "[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://$user.github.io/$test_pkg.jl/stable)"
        "[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://$user.github.io/$test_pkg.jl/latest)"
    ]

    p = Bar()
    @test isempty(badges(p, user, test_pkg))
    p = Baz()
    @test isempty(badges(p, user, test_pkg))
end

@testset "File generation" begin
    t = Template(;
        user="invenia",
        license="MPL",
        git_config=git_config,
        plugins=[Coveralls(), TravisCI(), CodeCov(), GitHubPages(), AppVeyor()],
    )
    pkg_dir = joinpath(t.temp_dir, test_pkg)

    temp_file = tempname()
    gen_file(temp_file, "Hello, world")
    @test isfile(temp_file)
    @test readstring(temp_file) == "Hello, world\n"
    rm(temp_file)

    @test gen_readme(test_pkg, t) == ["README.md"]
    @test isfile(joinpath(pkg_dir, "README.md"))
    readme = readchomp(joinpath(pkg_dir, "README.md"))
    rm(joinpath(pkg_dir, "README.md"))
    @test contains(readme, "# $test_pkg")
    for p in values(t.plugins)
        @test contains(readme, join(badges(p, t.user, test_pkg), "\n"))
    end
    # Check the order of the badges.
    @test search(readme, "github.io").start <
        search(readme, "travis").start <
        search(readme, "appveyor").start <
        search(readme, "codecov").start <
        search(readme, "coveralls").start
    # Plugins with badges but not in BADGE_ORDER should appear at the far right side.
    t.plugins[Foo] = Foo()
    gen_readme(test_pkg, t)
    readme = readchomp(joinpath(pkg_dir, "README.md"))
    rm(joinpath(pkg_dir, "README.md"))
    @test search(readme, "coveralls").start < search(readme, "baz").start

    @test gen_gitignore(test_pkg, t) == [".gitignore"]
    @test isfile(joinpath(pkg_dir, ".gitignore"))
    gitignore = readstring(joinpath(pkg_dir, ".gitignore"))
    rm(joinpath(pkg_dir, ".gitignore"))
    @test contains(gitignore, ".DS_Store")
    for p in values(t.plugins)
        for entry in p.gitignore
            @test contains(gitignore, entry)
        end
    end

    @test gen_license(test_pkg, t) == ["LICENSE"]
    @test isfile(joinpath(pkg_dir, "LICENSE"))
    license = readchomp(joinpath(pkg_dir, "LICENSE"))
    rm(joinpath(pkg_dir, "LICENSE"))
    @test contains(license, t.authors)
    @test contains(license, t.years)
    @test contains(license, read_license(t.license))

    @test gen_entrypoint(test_pkg, t) == ["src/"]
    @test isdir(joinpath(pkg_dir, "src"))
    @test isfile(joinpath(pkg_dir, "src", "$test_pkg.jl"))
    entrypoint = readchomp(joinpath(pkg_dir, "src", "$test_pkg.jl"))
    rm(joinpath(pkg_dir, "src"); recursive=true)
    @test contains(entrypoint, "module $test_pkg")

    @test gen_require(test_pkg, t) == ["REQUIRE"]
    @test isfile(joinpath(pkg_dir, "REQUIRE"))
    vf = version_floor(t.julia_version)
    @test readchomp(joinpath(pkg_dir, "REQUIRE")) == "julia $vf"
    rm(joinpath(pkg_dir, "REQUIRE"))

    @test gen_tests(test_pkg, t) == ["test/"]
    @test isdir(joinpath(pkg_dir, "test"))
    @test isfile(joinpath(pkg_dir, "test", "runtests.jl"))
    runtests = readchomp(joinpath(pkg_dir, "test", "runtests.jl"))
    rm(joinpath(pkg_dir, "test"); recursive=true)
    @test contains(runtests, "using $test_pkg")
    @test contains(runtests, "using Base.Test")

    rm(t.temp_dir; recursive=true)
end

@testset "Package generation" begin
    t = Template(; user="invenia")
    generate(test_pkg, t)
    @test !isfile(Pkg.dir(test_pkg, "LICENSE"))
    @test isfile(Pkg.dir(test_pkg, "README.md"))
    @test isfile(Pkg.dir(test_pkg, "REQUIRE"))
    @test isfile(Pkg.dir(test_pkg, ".gitignore"))
    @test isdir(Pkg.dir(test_pkg, "src"))
    @test isfile(Pkg.dir(test_pkg, "src", "$test_pkg.jl"))
    @test isdir(Pkg.dir(test_pkg, "test"))
    @test isfile(Pkg.dir(test_pkg, "test", "runtests.jl"))
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    branches = [LibGit2.shortname(branch[1]) for branch in LibGit2.GitBranchIter(repo)]
    @test LibGit2.getconfig(repo, "user.name", "") == LibGit2.getconfig("user.name", "")
    @test LibGit2.url(remote) == "https://github.com/invenia/$test_pkg.jl"
    @test in("master", branches)
    @test !in("gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir(test_pkg); recursive=true)

    generate(test_pkg, t; ssh=true)
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "git@github.com:invenia/$test_pkg.jl.git"
    rm(Pkg.dir(test_pkg); recursive=true)

    t = Template(; user="invenia", host="gitlab.com")
    generate(test_pkg, t)
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "https://gitlab.com/invenia/$test_pkg.jl"
    rm(Pkg.dir(test_pkg); recursive=true)

    temp_dir = mktempdir()
    t = Template(; user="invenia", dir=temp_dir)
    generate(test_pkg, t)
    @test isdir(joinpath(temp_dir, test_pkg))
    rm(temp_dir; recursive=true)

    t = Template(;
        user="invenia",
        license="MIT",
        git_config=git_config,
        plugins=[AppVeyor(), GitHubPages(), Coveralls(), CodeCov(), TravisCI()],
    )
    generate(test_pkg, t)
    @test isfile(Pkg.dir(test_pkg, "LICENSE"))
    @test isfile(Pkg.dir(test_pkg, ".travis.yml"))
    @test isfile(Pkg.dir(test_pkg, ".appveyor.yml"))
    @test isfile(Pkg.dir(test_pkg, ".codecov.yml"))
    @test isdir(Pkg.dir(test_pkg, "docs"))
    @test isfile(Pkg.dir(test_pkg, "docs", "make.jl"))
    @test isdir(Pkg.dir(test_pkg, "docs", "src"))
    @test isfile(Pkg.dir(test_pkg, "docs", "src", "index.md"))
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    @test LibGit2.getconfig(repo, "user.name", "") == git_config["user.name"]
    branches = [LibGit2.shortname(branch[1]) for branch in LibGit2.GitBranchIter(repo)]
    @test in("gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir(test_pkg); recursive=true)

    mkdir(Pkg.dir(test_pkg))
    @test_throws ArgumentError generate(test_pkg, t)
    generate(test_pkg, t; force=true)
    @test isfile(Pkg.dir(test_pkg, "README.md"))
    rm(Pkg.dir(test_pkg); recursive=true)

    t = Template(; user="invenia", plugins=[GitHubPages()])
    generate(test_pkg, t)
    readme = readstring(Pkg.dir(test_pkg, "README.md"))
    index = readstring(Pkg.dir(test_pkg, "docs", "src", "index.md"))
    @test readme == index
    rm(Pkg.dir(test_pkg); recursive=true)
end

@testset "Plugin generation" begin
    t = Template(; user="invenia")
    pkg_dir = joinpath(t.temp_dir, test_pkg)

    p = TravisCI()
    @test gen_plugin(p, t, test_pkg) == [".travis.yml"]
    @test isfile(joinpath(pkg_dir, ".travis.yml"))
    travis = readstring(joinpath(pkg_dir, ".travis.yml"))
    @test !contains(travis, "after_success")
    @test !contains(travis, "Codecov.submit")
    @test !contains(travis, "Coveralls.submit")
    @test !contains(travis, "Pkg.add(\"Documenter\")")
    rm(joinpath(pkg_dir, ".travis.yml"))
    t.plugins[CodeCov] = CodeCov()
    gen_plugin(p, t, test_pkg)
    delete!(t.plugins, CodeCov)
    travis = readstring(joinpath(pkg_dir, ".travis.yml"))
    @test contains(travis, "after_success")
    @test contains(travis, "Codecov.submit")
    @test !contains(travis, "Coveralls.submit")
    @test !contains(travis, "Pkg.add(\"Documenter\")")
    rm(joinpath(pkg_dir, ".travis.yml"))
    t.plugins[Coveralls] = Coveralls()
    gen_plugin(p, t, test_pkg)
    delete!(t.plugins, Coveralls)
    travis = readstring(joinpath(pkg_dir, ".travis.yml"))
    @test contains(travis, "after_success")
    @test contains(travis, "Coveralls.submit")
    @test !contains(travis, "Codecov.submit")
    @test !contains(travis, "Pkg.add(\"Documenter\")")
    rm(joinpath(pkg_dir, ".travis.yml"))
    t.plugins[GitHubPages] = GitHubPages()
    gen_plugin(p, t, test_pkg)
    delete!(t.plugins, GitHubPages)
    travis = readstring(joinpath(pkg_dir, ".travis.yml"))
    @test contains(travis, "after_success")
    @test contains(travis, "Pkg.add(\"Documenter\")")
    @test !contains(travis, "Codecov.submit")
    @test !contains(travis, "Coveralls.submit")
    rm(joinpath(pkg_dir, ".travis.yml"))
    p = TravisCI(; config_file=nothing)
    @test isempty(gen_plugin(p, t, test_pkg))
    @test !isfile(joinpath(pkg_dir, ".travis.yml"))
    @test_throws ArgumentError TravisCI(; config_file=fake_path)

    p = AppVeyor()
    @test gen_plugin(p, t, test_pkg) == [".appveyor.yml"]
    @test isfile(joinpath(pkg_dir, ".appveyor.yml"))
    appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
    @test !contains(appveyor, "after_script")
    @test !contains(appveyor, "Codecov.submit")
    @test !contains(appveyor, "Coveralls.submit")
    rm(joinpath(pkg_dir, ".appveyor.yml"))
    t.plugins[CodeCov] = CodeCov()
    gen_plugin(p, t, test_pkg)
    delete!(t.plugins, CodeCov)
    appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
    @test contains(appveyor, "after_script")
    @test contains(appveyor, "Codecov.submit")
    @test !contains(appveyor, "Coveralls.submit")
    rm(joinpath(pkg_dir, ".appveyor.yml"))
    t.plugins[Coveralls] = Coveralls()
    gen_plugin(p, t, test_pkg)
    delete!(t.plugins, Coveralls)
    appveyor = readstring(joinpath(pkg_dir, ".appveyor.yml"))
    @test contains(appveyor, "after_script")
    @test contains(appveyor, "Coveralls.submit")
    @test !contains(appveyor, "Codecov.submit")
    rm(joinpath(pkg_dir, ".appveyor.yml"))
    p = AppVeyor(; config_file=nothing)
    @test isempty(gen_plugin(p, t, test_pkg))
    @test !isfile(joinpath(pkg_dir, ".appveyor.yml"))
    @test_throws ArgumentError AppVeyor(; config_file=fake_path)

    p = CodeCov()
    @test gen_plugin(p, t, test_pkg) == [".codecov.yml"]
    @test isfile(joinpath(pkg_dir, ".codecov.yml"))
    rm(joinpath(pkg_dir, ".codecov.yml"))
    p = CodeCov(; config_file=nothing)
    @test isempty(gen_plugin(p, t, test_pkg))
    @test !isfile(joinpath(pkg_dir, ".codecov.yml"))
    @test_throws ArgumentError CodeCov(; config_file=fake_path)

    p = GitHubPages()
    @test gen_plugin(p, t, test_pkg) == ["docs/"]
    @test isdir(joinpath(pkg_dir, "docs"))
    @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
    make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
    @test contains(make, "assets=[]")
    @test !contains(make, "deploydocs")
    @test isdir(joinpath(pkg_dir, "docs", "src"))
    @test isfile(joinpath(pkg_dir, "docs", "src", "index.md"))
    index = readchomp(joinpath(pkg_dir, "docs", "src", "index.md"))
    @test index == "# $test_pkg"
    rm(joinpath(pkg_dir, "docs"); recursive=true)
    p = GitHubPages(; assets=[test_file])
    @test gen_plugin(p, t, test_pkg) == ["docs/"]
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
    @test gen_plugin(p, t, test_pkg) == ["docs/"]
    make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
    @test contains(make, "deploydocs")
    rm(joinpath(pkg_dir, "docs"); recursive=true)
    @test_throws ArgumentError GitHubPages(; assets=[fake_path])

    p = Bar()
    @test isempty(gen_plugin(p, t, test_pkg))
    p = Baz()
    @test isempty(gen_plugin(p, t, test_pkg))

    rm(t.temp_dir; recursive=true)
end

@testset "Version floor" begin
    @test version_floor(v"1.0.0") == "1.0"
    @test version_floor(v"1.0.1") == "1.0"
    @test version_floor(v"1.0.1-pre") == "1.0"
    @test version_floor(v"1.0.0-pre") == "1.0-"
end

@testset "Mustache substitution" begin
    view = Dict{String, Any}()
    text = substitute(template_text, view)
    @test !contains(text, "PKGNAME: $test_pkg")
    @test !contains(text, "Documenter")
    @test !contains(text, "CodeCov")
    @test !contains(text, "Coveralls")
    @test !contains(text, "After")
    @test !contains(text, "Other")
    view["PKGNAME"] = test_pkg
    view["OTHER"] = true
    text = substitute(template_text, view)
    @test contains(text, "PKGNAME: $test_pkg")
    @test contains(text, "Other")

    t = Template(; user="invenia")
    rm(t.temp_dir; recursive=true)
    view["OTHER"] = false

    text = substitute(template_text, t; view=view)
    @test contains(text, "PKGNAME: $test_pkg")
    @test contains(text, "VERSION: $(t.julia_version.major).$(t.julia_version.minor)")
    @test !contains(text, "Documenter")
    @test !contains(text, "After")
    @test !contains(text, "Other")

    t.plugins[GitHubPages] = GitHubPages()
    text = substitute(template_text, t; view=view)
    @test contains(text, "Documenter")
    @test contains(text, "After")
    empty!(t.plugins)

    t.plugins[CodeCov] = CodeCov()
    text = substitute(template_text, t; view=view)
    @test contains(text, "CodeCov")
    @test contains(text, "After")
    empty!(t.plugins)

    t.plugins[CodeCov] = Coveralls()
    text = substitute(template_text, t; view=view)
    @test contains(text, "Coveralls")
    @test contains(text, "After")
    empty!(t.plugins)

    view["OTHER"] = true
    text = substitute(template_text, t; view=view)
    @test contains(text, "Other")
end

@testset "License display" begin
    old_stdout = STDOUT
    out_read, out_write = redirect_stdout()
    show_license()
    licenses = join(Char(c) for c in readavailable(out_read))
    show_license("MIT")
    mit = join(Char(c) for c in readavailable(out_read))
    close(out_write)
    close(out_read)
    redirect_stdout(old_stdout)

    for (short, long) in LICENSES
        @test contains(licenses, "$short: $long")
    end
    @test strip(mit) == strip(read_license("MIT"))
    @test strip(read_license("MIT")) == strip(readstring(joinpath(LICENSE_DIR, "MIT")))
    @test_throws ArgumentError read_license(fake_path)
end

rm(test_file)
