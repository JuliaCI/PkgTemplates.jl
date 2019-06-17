# A dummy GenericPlugin subtype.
struct Foo <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Union{AbstractString, Nothing}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}
    function Foo(; config_file=test_file)
        new([], @__FILE__, config_file, [Badge("foo", "bar", "baz")], Dict{String, Any}())
    end
end
# A dummy CustomPlugin subtype.
struct Bar <: CustomPlugin end
# A dummy Plugin subtype.
struct Baz <: Plugin end
# A Documenter with extra kwargs
struct Qux <: Documenter
    assets::Vector{AbstractString}
    additional_kwargs::Union{AbstractDict, NamedTuple}
end

# Various options to be passed into templates.
const me = "christopher-dG"
const test_pkg = "TestPkg"
const fake_path = "/dev/null/this/file/does/not/exist"
const test_file = tempname()
const default_dir = Pkg.devdir()
const gitconfig = GitConfig(joinpath(@__DIR__, "gitconfig"))
const template_text = """
    PKGNAME: {{PKGNAME}}
    VERSION: {{VERSION}}}
    {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
    {{#CODECOV}}Codecov{{/CODECOV}}
    {{#COVERALLS}}Coveralls{{/COVERALLS}}
    {{#AFTER}}After{{/AFTER}}
    {{#OTHER}}Other{{/OTHER}}
    """
write(test_file, template_text)

@testset "Template creation" begin
    # Checking default field assignments.
    t = Template(; authors="foo", user=me)
    @test t.user == me
    @test t.license == "MIT"
    @test t.authors == "foo"
    @test t.dir == default_dir
    @test t.julia_version == PkgTemplates.default_version()
    @test !t.ssh
    @test !t.manifest
    @test isempty(t.plugins)

    # Checking non-default field assignments.

    t = Template(; user=me, license="")
    @test t.license == ""

    t = Template(; user=me, license="MPL")
    @test t.license == "MPL"

    t = Template(; user=me, authors="Some Guy")
    @test t.authors == "Some Guy"
    # Vectors of authors should be comma-joined.
    t = Template(; user=me, authors=["Guy", "Gal"])
    @test t.authors == "Guy, Gal"

    t = Template(; user=me, dir=test_file)
    @test t.dir == abspath(test_file)
    if Sys.isunix()  # ~ means temporary file on Windows, not $HOME.
        # '~' should be replaced by home dir.
        t = Template(; user=me, dir="~/$(basename(test_file))")
        @test t.dir == joinpath(homedir(), basename(test_file))
    end

    t = Template(; user=me, julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(; user=me, ssh=true)
    @test t.ssh

    t = Template(; user=me, manifest=true)
    @test t.manifest

    # The template should contain whatever plugins you give it.
    t = Template(;
        user=me,
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), Codecov(), Coveralls()],
    )
    @test Set(keys(t.plugins)) == Set(map(typeof, values(t.plugins))) == Set(
        [GitHubPages, TravisCI, AppVeyor, Codecov, Coveralls]
    )

    # Duplicate plugins should warn.
    @test_logs (:warn, r"duplicates") match_mode=:any t = Template(;
        user=me,
        plugins=[TravisCI(), TravisCI()],
    )

    # If github.user is configured, use that as a default.
    if isempty(LibGit2.getconfig("github.user", ""))
        @test_throws ArgumentError Template()
    else
        t = Template()
        @test t.user == LibGit2.getconfig("github.user", "")
    end
    @test_throws ArgumentError Template(; user=me, license="FakeLicense")
end

@testset "Show methods" begin
    pkg_dir = replace(default_dir, homedir() => "~")
    ver = PkgTemplates.version_floor(PkgTemplates.default_version())
    buf = IOBuffer()
    t = Template(; user=me, authors="foo")
    show(buf, t)
    text = String(take!(buf))
    expected = """
        Template:
          → User: $me
          → Host: github.com
          → License: MIT (foo $(year(today())))
          → Package directory: $pkg_dir
          → Minimum Julia version: v$ver
          → SSH remote: No
          → Add packages to main environment: Yes
          → Commit Manifest.toml: No
          → Plugins: None
        """
    @test text == rstrip(expected)
    t = Template(
        user=me,
        license="",
        ssh=true,
        manifest=true,
        plugins=[
            TravisCI(),
            Codecov(),
            GitHubPages(),
        ],
    )
    show(buf, t)
    text = String(take!(buf))
    expected = """
        Template:
          → User: $me
          → Host: github.com
          → License: None
          → Package directory: $pkg_dir
          → Minimum Julia version: v$ver
          → SSH remote: Yes
          → Add packages to main environment: Yes
          → Commit Manifest.toml: Yes
          → Plugins:
            • Codecov:
              → Config file: None
              → 3 gitignore entries: "*.jl.cov", "*.jl.*.cov", "*.jl.mem"
            • GitHubPages:
              → 0 asset files
              → 2 gitignore entries: "/docs/build/", "/docs/site/"
            • TravisCI:
              → Config file: Default
              → 0 gitignore entries
        """
    @test text == rstrip(expected)
end

@testset "File generation" begin
    t = Template(;
        user=me,
        license="MPL",
        plugins=[Coveralls(), TravisCI(), Codecov(), GitHubPages(), AppVeyor()],
    )
    temp_dir = mktempdir()
    pkg_dir = joinpath(temp_dir, test_pkg)

    temp_file = tempname()
    gen_file(temp_file, "Hello, world")
    @test isfile(temp_file)
    @test read(temp_file, String) == "Hello, world\n"
    rm(temp_file)

    # Test the README generation.
    @test gen_readme(pkg_dir, t) == ["README.md"]
    @test isfile(joinpath(pkg_dir, "README.md"))
    readme = readchomp(joinpath(pkg_dir, "README.md"))
    rm(joinpath(pkg_dir, "README.md"))
    @test occursin("# $test_pkg", readme)
    for p in values(t.plugins)
        @test occursin(join(badges(p, t.user, test_pkg), "\n"), readme)
    end
    # Check the order of the badges.
    @test something(findfirst("github.io", readme)).start <
        something(findfirst("travis", readme)).start <
        something(findfirst("appveyor", readme)).start <
        something(findfirst("codecov", readme)).start <
        something(findfirst("coveralls", readme)).start
    # Plugins with badges but not in BADGE_ORDER should appear at the far right side.
    t.plugins[Foo] = Foo()
    gen_readme(pkg_dir, t)
    readme = readchomp(joinpath(pkg_dir, "README.md"))
    rm(joinpath(pkg_dir, "README.md"))
    @test findfirst("coveralls", readme).start < findfirst("baz", readme).start

    # Test the gitignore generation.
    @test gen_gitignore(pkg_dir, t) == [".gitignore"]
    @test isfile(joinpath(pkg_dir, ".gitignore"))
    gitignore = read(joinpath(pkg_dir, ".gitignore"), String)
    rm(joinpath(pkg_dir, ".gitignore"))
    @test occursin(".DS_Store", gitignore)
    @test occursin("Manifest.toml", gitignore)
    for p in values(t.plugins)
        for entry in p.gitignore
            @test occursin(entry, gitignore)
        end
    end
    t = Template(; user=me, manifest=true)
    @test gen_gitignore(pkg_dir, t) == [".gitignore", "Manifest.toml"]
    gitignore = read(joinpath(pkg_dir, ".gitignore"), String)
    @test !occursin("Manifest.toml", gitignore)
    rm(joinpath(pkg_dir, ".gitignore"))

    # Test the license generation.
    @test gen_license(pkg_dir, t) == ["LICENSE"]
    @test isfile(joinpath(pkg_dir, "LICENSE"))
    license = readchomp(joinpath(pkg_dir, "LICENSE"))
    rm(joinpath(pkg_dir, "LICENSE"))
    @test occursin(t.authors, license)
    @test occursin(read_license(t.license), license)

    # Test the test generation.
    @test gen_tests(pkg_dir, t) == ["test/"]
    @test isfile(joinpath(pkg_dir, "Project.toml"))
    project = read(joinpath(pkg_dir, "Project.toml"), String)
    @test occursin("[extras]\nTest = ", project)
    @test isdir(joinpath(pkg_dir, "test"))
    @test isfile(joinpath(pkg_dir, "test", "runtests.jl"))
    @test isfile(joinpath(pkg_dir, "Manifest.toml"))
    runtests = read(joinpath(pkg_dir, "test", "runtests.jl"), String)
    rm(joinpath(pkg_dir, "test"); recursive=true)
    @test occursin("using $test_pkg", runtests)
    @test occursin("using Test", runtests)
    manifest = read(joinpath(pkg_dir, "Manifest.toml"), String)
    @test !occursin("[[Test]]", manifest)

    rm(temp_dir; recursive=true)
end

@testset "Package generation" begin
    t = Template(; user=me)
    generate(test_pkg, t; gitconfig=gitconfig)
    pkg_dir = joinpath(default_dir, test_pkg)

    # Check that the expected files all exist.
    @test isfile(joinpath(pkg_dir, "LICENSE"))
    @test isfile(joinpath(pkg_dir, "README.md"))
    @test isfile(joinpath(pkg_dir, ".gitignore"))
    @test isdir(joinpath(pkg_dir, "src"))
    @test isfile(joinpath(pkg_dir, "src", "$test_pkg.jl"))
    @test isfile(joinpath(pkg_dir, "Project.toml"))
    @test isdir(joinpath(pkg_dir, "test"))
    @test isfile(joinpath(pkg_dir, "test", "runtests.jl"))
    @test isfile(joinpath(pkg_dir, "Manifest.toml"))
    # Check the configured remote and branches.
    # Note: This test will fail on your system if you've configured Git
    # to replace all HTTPS URLs with SSH.
    repo = LibGit2.GitRepo(pkg_dir)
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    branches = map(b -> LibGit2.shortname(first(b)), LibGit2.GitBranchIter(repo))
    @test LibGit2.url(remote) == "https://github.com/$me/$test_pkg.jl"
    @test branches == ["master"]
    @test !LibGit2.isdirty(repo)
    # Check for the [compat] section.
    project = read(joinpath(pkg_dir, "Project.toml"), String)
    @test occursin("[compat]", project)
    @test occursin("julia = " * PkgTemplates.repr_version(t.julia_version), project)
    rm(pkg_dir; recursive=true)

    # Check that the remote is an SSH URL when we want it to be.
    t = Template(; user=me, ssh=true)
    generate(t, test_pkg; gitconfig=gitconfig)  # Test the reversed-arguments method here.
    repo = LibGit2.GitRepo(pkg_dir)
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "git@github.com:$me/$test_pkg.jl.git"
    rm(pkg_dir; recursive=true)

    # Check that the remote is set correctly for non-default hosts.
    t = Template(; user=me, host="gitlab.com")
    generate(test_pkg, t; gitconfig=gitconfig)
    repo = LibGit2.GitRepo(pkg_dir)
    remote = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    @test LibGit2.url(remote) == "https://gitlab.com/$me/$test_pkg.jl"
    rm(pkg_dir; recursive=true)

    # Check that the package ends up in the right directory.
    temp_dir = mktempdir()
    t = Template(; user=me, dir=temp_dir)
    generate(test_pkg, t; gitconfig=gitconfig)
    @test isdir(joinpath(temp_dir, test_pkg))
    rm(temp_dir; recursive=true)

    # Check that the Manifest.toml is not commited by default.
    t = Template(; user=me)
    generate(test_pkg, t; gitconfig=gitconfig)
    @test occursin("Manifest.toml", read(joinpath(pkg_dir, ".gitignore"), String))
    # I'm not sure this is the "right" way to do this.
    repo = GitRepo(pkg_dir)
    idx = LibGit2.GitIndex(repo)
    @test findall("Manifest.toml", idx) === nothing
    rm(pkg_dir; recursive=true)

    # And that it is when you tell it to be.
    t = Template(; user=me, manifest=true)
    generate(test_pkg, t; gitconfig=gitconfig)
    @test !occursin("Manifest.toml", read(joinpath(pkg_dir, ".gitignore"), String))
    # I'm not sure this is the "right" way to do this.
    repo = GitRepo(pkg_dir)
    idx = LibGit2.GitIndex(repo)
    @test findall("Manifest.toml", idx) !== nothing
    rm(pkg_dir; recursive=true)

    # Check that the created package ends up developed in the current environment.
    temp_dir = mktempdir()
    Pkg.activate(temp_dir)
    t = Template(; user=me)
    generate(test_pkg, t; gitconfig=gitconfig)
    @test haskey(Pkg.installed(), test_pkg)
    rm(pkg_dir; recursive=true)
    Pkg.activate()
    rm(temp_dir; recursive=true)
end

@testset "Git-less template creation" begin
    if isempty(LibGit2.getconfig("user.name", ""))
        @test_logs Template(; user=me, git=false)
    end
end

@testset "Git-less package generation" begin
    t = Template(; user=me)
    generate(test_pkg, t; git=false)
    @test !ispath(joinpath(t.dir, ".git"))
    @test !isfile(joinpath(t.dir, ".gitignore"))
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
    @test !occursin("PKGNAME: $test_pkg", text)
    @test !occursin("Documenter", text)
    @test !occursin("Codecov", text)
    @test !occursin("Coveralls", text)
    @test !occursin("After", text)
    @test !occursin("Other", text)
    view["PKGNAME"] = test_pkg
    view["OTHER"] = true
    text = substitute(template_text, view)
    @test occursin("PKGNAME: $test_pkg", text)
    @test occursin("Other", text)

    t = Template(; user=me)
    view["OTHER"] = false

    text = substitute(template_text, t; view=view)
    @test occursin("PKGNAME: $test_pkg", text)
    @test occursin("VERSION: $(t.julia_version.major).$(t.julia_version.minor)", text)
    @test !occursin("Documenter", text)
    @test !occursin("After", text)
    @test !occursin("Other", text)

    t.plugins[GitHubPages] = GitHubPages()
    text = substitute(template_text, t; view=view)
    @test occursin("Documenter", text)
    @test occursin("After", text)
    empty!(t.plugins)

    t.plugins[Codecov] = Codecov()
    text = substitute(template_text, t; view=view)
    @test occursin("Codecov", text)
    @test occursin("After", text)
    empty!(t.plugins)

    t.plugins[Coveralls] = Coveralls()
    text = substitute(template_text, t; view=view)
    @test occursin("Coveralls", text)
    @test occursin("After", text)
    empty!(t.plugins)

    view["OTHER"] = true
    text = substitute(template_text, t; view=view)
    @test occursin("Other", text)
end

@testset "License display" begin
    io = IOBuffer()
    available_licenses(io)
    licenses = String(take!(io))
    show_license(io, "MIT")
    mit = String(take!(io))

    # Check that all licenses are included in the display.
    for (short, long) in LICENSES
        @test occursin("$short: $long", licenses)
    end
    @test strip(mit) == strip(read_license("MIT"))
    @test strip(read_license("MIT")) == strip(read(joinpath(LICENSE_DIR, "MIT"), String))
    @test_throws ArgumentError read_license(fake_path)

    # Check that all licenses included with the package are displayed.
    for license in readdir(LICENSE_DIR)
        @test haskey(LICENSES, license)
    end
    # Check that all licenses displayed are included with the package.
    @test length(readdir(LICENSE_DIR)) == length(LICENSES)
end

@testset "Plugins" begin
    t = Template(; user=me)
    pkg_dir = joinpath(t.dir, test_pkg)

    # Check badge constructor and formatting.
    badge = Badge("A", "B", "C")
    @test badge.hover == "A"
    @test badge.image == "B"
    @test badge.link == "C"
    @test format(badge) == "[![A](B)](C)"

    p = Bar()
    @test isempty(badges(p, me, test_pkg))
    @test isempty(gen_plugin(p, t, test_pkg))

    p = Baz()
    @test isempty(badges(p, me, test_pkg))
    @test isempty(gen_plugin(p, t, test_pkg))

    include(joinpath("plugins", "travisci.jl"))
    include(joinpath("plugins", "appveyor.jl"))
    include(joinpath("plugins", "gitlabci.jl"))
    include(joinpath("plugins", "cirrusci.jl"))
    include(joinpath("plugins", "codecov.jl"))
    include(joinpath("plugins", "coveralls.jl"))
    include(joinpath("plugins", "githubpages.jl"))
    include(joinpath("plugins", "gitlabpages.jl"))
    include(joinpath("plugins", "citation.jl"))
end

@testset "Documenter add kwargs" begin
    t = Template(; user=me)
    pkg_dir = joinpath(t.dir, test_pkg)

    function check_kwargs(kwargs, warn_str)
        p = Qux([], kwargs)
        @test_logs (:warn, warn_str) gen_plugin(p, t, test_pkg)

        make = readchomp(joinpath(pkg_dir, "docs", "make.jl"))
        @test occursin("\n    stringarg=\"string\",\n", make)
        @test occursin("\n    strict=true,\n", make)
        @test occursin("\n    checkdocs=:none,\n", make)

        @test !occursin("format=:markdown", make)
        @test occursin("format=Documenter.HTML()", make)
        rm(pkg_dir; recursive=true)
    end
    # Test with string kwargs
    kwargs = Dict("checkdocs" => :none,
        "strict" => true,
        "format" => :markdown,
        "stringarg" => "string",
    )
    warn_str = "Ignoring predefined Documenter kwargs \"format\" from additional kwargs"
    check_kwargs(kwargs, warn_str)

    kwargs = Dict(:checkdocs => :none,
        :strict => true,
        :format => :markdown,
        :stringarg => "string",
    )
    warn_str = "Ignoring predefined Documenter kwargs :format from additional kwargs"
    check_kwargs(kwargs, warn_str)

    kwargs = (checkdocs = :none, strict = true, format = :markdown, stringarg = "string")
    warn_str = "Ignoring predefined Documenter kwargs :format from additional kwargs"
    check_kwargs(kwargs, warn_str)
end

include(joinpath("interactive", "interactive.jl"))

rm(test_file)
