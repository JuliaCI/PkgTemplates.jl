struct Foo <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}
    function Foo(; config_file=test_file)
        new([], @__FILE__, config_file, [Badge("foo", "bar", "baz")], Dict{String, Any}())
    end
end
struct Bar <: CustomPlugin end
struct Baz <: Plugin end

const me = "christopher-dG"
const gitconfig = Dict(
    "user.name" => "Tester McTestFace",
    "user.email" => "email@web.site",
    "github.user" => "TesterMcTestFace",
)
const test_pkg = "TestPkg"
const fake_path = bin(hash("/this/file/does/not/exist"))
const test_file = tempname()
const template_text = """
            PKGNAME: {{PKGNAME}}
            VERSION: {{VERSION}}}
            {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
            {{#CODECOV}}CodeCov{{/CODECOV}}
            {{#COVERALLS}}Coveralls{{/COVERALLS}}
            {{#AFTER}}After{{/AFTER}}
            {{#OTHER}}Other{{/OTHER}}
            """
write(test_file, template_text)

@testset "Template creation" begin
    t = Template(; user=me)
    @test t.user == me
    @test t.license == "MIT"
    @test t.years == string(Dates.year(Dates.today()))
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.dir == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.gitconfig)
    @test isempty(t.plugins)

    t = Template(; user=me, license="")
    @test t.license == ""

    t = Template(; user=me, license="MPL")
    @test t.license == "MPL"

    t = Template(; user=me, years=2014)
    @test t.years == "2014"
    t = Template(user=me, years="2014-2015")
    @test t.years == "2014-2015"

    t = Template(; user=me, authors="Some Guy")
    @test t.authors == "Some Guy"

    t = Template(; user=me, authors=["Guy", "Gal"])
    @test t.authors == "Guy, Gal"

    t = Template(; user=me, dir=test_file)
    @test t.dir == abspath(test_file)
    if is_unix()  # ~ means temporary file on Windows, not $HOME.
        t = Template(; user=me, dir="~/$(basename(test_file))")
        @test t.dir == joinpath(homedir(), basename(test_file))
    end

    t = Template(; user=me, julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(; user=me, requirements=["$test_pkg 0.1"])
    @test t.requirements == ["$test_pkg 0.1"]
    @test_warn r".+" t = Template(; user=me, requirements=[test_pkg, test_pkg])
    @test t.requirements == [test_pkg]
    @test_throws ArgumentError Template(;
        user=me,
        requirements=[test_pkg, "$test_pkg 0.1"]
    )

    t = Template(; user=me, gitconfig=gitconfig)
    @test t.gitconfig == gitconfig

    t = Template(; user=me, gitconfig=gitconfig)
    @test t.authors == gitconfig["user.name"]

    t = Template(; gitconfig=gitconfig)
    @test t.user == gitconfig["github.user"]
    @test t.authors == gitconfig["user.name"]

    t = Template(;
        user=me,
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov(), Coveralls()],
    )
    @test Set(keys(t.plugins)) == Set(
        [GitHubPages, TravisCI, AppVeyor, CodeCov, Coveralls]
    )
    @test Set(values(t.plugins)) == Set(
        [GitHubPages(), TravisCI(), AppVeyor(), CodeCov(), Coveralls()]
    )

    @test_warn r".+" t = Template(;
        user=me,
        plugins=[TravisCI(), TravisCI()],
    )

    if isempty(LibGit2.getconfig("github.user", ""))
        @test_throws ArgumentError Template()
    else
        t = Template()
        @test t.user == LibGit2.getconfig("github.user", "")
    end
    @test_throws ArgumentError Template(; user=me, license="FakeLicense")
end

if get(ENV, "TRAVIS_OS_NAME", "") != "osx"
    include(joinpath("interactive", "interactive.jl"))
else
    info("Skipping tests that require TerminalMenus")
end
@testset "Interactive plugin creation" begin
    include(joinpath("interactive", "plugins.jl"))
end


@testset "File generation" begin
    t = Template(;
        user=me,
        license="MPL",
        requirements=[test_pkg],
        gitconfig=gitconfig,
        plugins=[Coveralls(), TravisCI(), CodeCov(), GitHubPages(), AppVeyor()],
    )
    temp_dir = mktempdir()
    pkg_dir = joinpath(temp_dir, test_pkg)

    temp_file = tempname()
    gen_file(temp_file, "Hello, world")
    @test isfile(temp_file)
    @test readstring(temp_file) == "Hello, world\n"
    rm(temp_file)

    @test gen_readme(temp_dir, test_pkg, t) == ["README.md"]
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
    gen_readme(temp_dir, test_pkg, t)
    readme = readchomp(joinpath(pkg_dir, "README.md"))
    rm(joinpath(pkg_dir, "README.md"))
    @test search(readme, "coveralls").start < search(readme, "baz").start

    @test gen_gitignore(temp_dir, test_pkg, t) == [".gitignore"]
    @test isfile(joinpath(pkg_dir, ".gitignore"))
    gitignore = readstring(joinpath(pkg_dir, ".gitignore"))
    rm(joinpath(pkg_dir, ".gitignore"))
    @test contains(gitignore, ".DS_Store")
    for p in values(t.plugins)
        for entry in p.gitignore
            @test contains(gitignore, entry)
        end
    end

    @test gen_license(temp_dir, test_pkg, t) == ["LICENSE"]
    @test isfile(joinpath(pkg_dir, "LICENSE"))
    license = readchomp(joinpath(pkg_dir, "LICENSE"))
    rm(joinpath(pkg_dir, "LICENSE"))
    @test contains(license, t.authors)
    @test contains(license, t.years)
    @test contains(license, read_license(t.license))

    @test gen_entrypoint(temp_dir, test_pkg, t) == ["src/"]
    @test isdir(joinpath(pkg_dir, "src"))
    @test isfile(joinpath(pkg_dir, "src", "$test_pkg.jl"))
    entrypoint = readchomp(joinpath(pkg_dir, "src", "$test_pkg.jl"))
    rm(joinpath(pkg_dir, "src"); recursive=true)
    @test contains(entrypoint, "module $test_pkg")

    @test gen_require(temp_dir, test_pkg, t) == ["REQUIRE"]
    @test isfile(joinpath(pkg_dir, "REQUIRE"))
    vf = version_floor(t.julia_version)
    @test readchomp(joinpath(pkg_dir, "REQUIRE")) == "julia $vf\n$test_pkg"
    rm(joinpath(pkg_dir, "REQUIRE"))

    @test gen_tests(temp_dir, test_pkg, t) == ["test/"]
    @test isdir(joinpath(pkg_dir, "test"))
    @test isfile(joinpath(pkg_dir, "test", "runtests.jl"))
    runtests = readchomp(joinpath(pkg_dir, "test", "runtests.jl"))
    rm(joinpath(pkg_dir, "test"); recursive=true)
    @test contains(runtests, "using $test_pkg")
    @test contains(runtests, "using Base.Test")

    rm(temp_dir; recursive=true)
end

@testset "Package generation" begin
    t = Template(; user=me, gitconfig=gitconfig)
    generate(test_pkg, t)
    @test isfile(Pkg.dir(test_pkg, "LICENSE"))
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
    @test LibGit2.getconfig(repo, "user.name", "") == gitconfig["user.name"]
    @test LibGit2.url(remote) == "https://github.com/$me/$test_pkg.jl"
    @test in("master", branches)
    @test !in("gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir(test_pkg); recursive=true)

    generate(t, test_pkg; ssh=true)  # Test the reversed-arguments method.
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "git@github.com:$me/$test_pkg.jl.git"
    rm(Pkg.dir(test_pkg); recursive=true)

    t = Template(; user=me, host="gitlab.com", gitconfig=gitconfig)
    generate(test_pkg, t)
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "https://gitlab.com/$me/$test_pkg.jl"
    rm(Pkg.dir(test_pkg); recursive=true)

    temp_dir = mktempdir()
    t = Template(; user=me, dir=temp_dir, gitconfig=gitconfig)
    generate(test_pkg, t)
    @test isdir(joinpath(temp_dir, test_pkg))
    rm(temp_dir; recursive=true)

    t = Template(;
        user=me,
        license="",
        gitconfig=gitconfig,
        plugins=[AppVeyor(), GitHubPages(), Coveralls(), CodeCov(), TravisCI()],
    )
    generate(test_pkg, t)
    @test isdir(joinpath(Pkg.dir(), test_pkg))
    @test !isfile(Pkg.dir(test_pkg, "LICENSE"))
    @test isfile(Pkg.dir(test_pkg, ".travis.yml"))
    @test isfile(Pkg.dir(test_pkg, ".appveyor.yml"))
    @test isfile(Pkg.dir(test_pkg, ".codecov.yml"))
    @test isdir(Pkg.dir(test_pkg, "docs"))
    @test isfile(Pkg.dir(test_pkg, "docs", "make.jl"))
    @test isdir(Pkg.dir(test_pkg, "docs", "src"))
    @test isfile(Pkg.dir(test_pkg, "docs", "src", "index.md"))
    repo = LibGit2.GitRepo(Pkg.dir(test_pkg))
    @test LibGit2.getconfig(repo, "user.name", "") == gitconfig["user.name"]
    branches = [LibGit2.shortname(branch[1]) for branch in LibGit2.GitBranchIter(repo)]
    @test in("gh-pages", branches)
    @test !LibGit2.isdirty(repo)
    rm(Pkg.dir(test_pkg); recursive=true)

    mkdir(Pkg.dir(test_pkg))
    @test_throws ArgumentError generate(test_pkg, t)
    generate(test_pkg, t; force=true)
    @test isfile(Pkg.dir(test_pkg, "README.md"))
    rm(Pkg.dir(test_pkg); recursive=true)

    temp_file, fd = mktemp()
    close(fd)
    temp_dir = mktempdir()
    t = Template(; user=me, dir=temp_file, gitconfig=gitconfig)
    @test_warn r".+" generate(test_pkg, t; backup_dir=temp_dir)
    rm(temp_dir; recursive=true)
    temp_dir = mktempdir()
    t = Template(; user=me, dir=joinpath(temp_file, "file"), gitconfig=gitconfig)
    @test_warn r".+" generate(test_pkg, t; backup_dir=temp_dir)
    rm(temp_dir; recursive=true)
    rm(temp_file)

    t = Template(; user=me, gitconfig=gitconfig, plugins=[GitHubPages()])
    generate(test_pkg, t)
    readme = readstring(Pkg.dir(test_pkg, "README.md"))
    index = readstring(Pkg.dir(test_pkg, "docs", "src", "index.md"))
    @test readme == index
    rm(Pkg.dir(test_pkg); recursive=true)
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

    t = Template(; user=me)
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

    t.plugins[Coveralls] = Coveralls()
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
    available_licenses()
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

@testset "Plugins" begin
    user = gitconfig["github.user"]
    t = Template(; user=me)
    temp_dir = mktempdir()
    pkg_dir = joinpath(temp_dir, test_pkg)

    badge = Badge("A", "B", "C")
    @test badge.hover == "A"
    @test badge.image == "B"
    @test badge.link == "C"
    @test format(badge) == "[![A](B)](C)"

    p = Bar()
    @test isempty(badges(p, user, test_pkg))
    @test isempty(gen_plugin(p, t, temp_dir, test_pkg))

    p = Baz()
    @test isempty(badges(p, user, test_pkg))
    @test isempty(gen_plugin(p, t, temp_dir, test_pkg))

    include(joinpath("plugins", "travisci.jl"))
    include(joinpath("plugins", "appveyor.jl"))
    include(joinpath("plugins", "gitlabci.jl"))
    include(joinpath("plugins", "codecov.jl"))
    include(joinpath("plugins", "coveralls.jl"))
    include(joinpath("plugins", "githubpages.jl"))

    rm(temp_dir; recursive=true)
end

rm(test_file)
