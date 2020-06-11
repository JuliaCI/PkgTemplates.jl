@info "Running reference tests"

const PROMPT = get(ENV, "PT_INTERACTIVE", "false") == "true" || !haskey(ENV, "CI")
const STATIC_FILE = joinpath(@__DIR__, "fixtures", "static.txt")
const STATIC_DOCUMENTER = [
    PackageSpec(; name="DocStringExtensions", version=v"0.8.1"),
    PackageSpec(; name="Documenter", version=v"0.24.2"),
    PackageSpec(; name="JSON", version=v"0.21.0"),
    PackageSpec(; name="Parsers", version=v"0.3.10"),
]

function test_reference(reference, comparison)
    if !isfile(comparison)
        # If the comparison file doesn't yet exist, create it and pass the test.
        @info "Creating new reference file $comparison"
        copy_file(reference, comparison)
        @test true
        return
    end

    a = read(reference, String)
    b = read(comparison, String)
    if a == b
        # If the files are equal, pass the test.
        @test true
        return
    end

    print_diff(a, b)
    println("Reference and comparison files do not match (see above)")
    println("Reference: $reference")
    println("Comparison: $comparison")
    update = false
    if PROMPT
        while true
            println("Update reference file? [y/n]")
            answer = lowercase(strip(readline()))
            if startswith(answer, "y") || startswith(answer, "n")
                # If the user chooses to update the reference file,
                # replace its contents with the comparison file.
                startswith(answer, "y") && copy_file(comparison, reference)
                break
            end
        end
    end

    # Fail the test, but keep the output short
    # because we've already showed the diff.
    @test :reference == :comparison
end

function copy_file(src::AbstractString, dest::AbstractString)
    mkpath(dirname(dest))
    cp(src, dest; force=true)
end

PT.user_view(::Citation, ::Template, ::AbstractString) = Dict("MONTH" => 8, "YEAR" => 2019)
PT.user_view(::License, ::Template, ::AbstractString) = Dict("YEAR" => 2019)

function pin_documenter(project_dir::AbstractString)
    @suppress PT.with_project(project_dir) do
        foreach(Pkg.add, STATIC_DOCUMENTER)
    end
    toml = joinpath(project_dir, "Project.toml")
    project = TOML.parsefile(toml)
    filter!(p -> p.first == "Documenter", project["deps"])
    open(io -> TOML.print(io, project), toml, "w")
end

function test_all(pkg::AbstractString; kwargs...)
    t = tpl(; kwargs...)
    with_pkg(t, pkg) do pkg
        pkg_dir = joinpath(t.dir, pkg)
        PT.hasplugin(t, Documenter) && pin_documenter(joinpath(pkg_dir, "docs"))
        foreach(readlines(`git -C $pkg_dir ls-files`)) do f
            reference = joinpath(@__DIR__, "fixtures", pkg, f)
            comparison = joinpath(pkg_dir, f)
            test_reference(reference, comparison)
        end
    end
end

@testset "Reference tests" begin
    @testset "Default package" begin
        test_all("Basic"; authors=USER)
    end

    @testset "All plugins" begin
        test_all("AllPlugins"; authors=USER, plugins=[
            AppVeyor(), CirrusCI(), Citation(), Codecov(), CompatHelper(), Coveralls(),
            Develop(), Documenter(), DroneCI(), GitHubActions(), GitLabCI(), TravisCI(),
        ])
    end

    @testset "Documenter (TravisCI)" begin
        test_all("DocumenterTravis"; authors=USER, plugins=[
            Documenter{TravisCI}(), TravisCI(),
        ])
    end

    @testset "Documenter (GitHubActions)" begin
        test_all("DocumenterGitHubActions"; authors=USER, plugins=[
            Documenter{GitHubActions}(), GitHubActions(),
        ])
    end


    @testset "Wacky options" begin
        test_all("WackyOptions"; authors=USER, julia=v"1.2", host="x.com", plugins=[
            AppVeyor(; x86=true, coverage=true, extra_versions=[v"1.1"]),
            CirrusCI(; image="freebsd-123", coverage=false, extra_versions=["1.3"]),
            Citation(; readme=true),
            Codecov(; file=STATIC_FILE),
            CompatHelper(; cron="0 0 */3 * *"),
            Coveralls(; file=STATIC_FILE),
            Documenter{GitLabCI}(
                assets=[STATIC_FILE],
                makedocs_kwargs=Dict(:foo => "bar", :bar => "baz"),
                canonical_url=(_t, _pkg) -> "http://example.com",
            ),
            DroneCI(; amd64=false, arm=true, arm64=true, extra_versions=["1.3"]),
            Git(; ignore=["a", "b", "c"], manifest=true),
            GitHubActions(; x86=true, linux=false, coverage=false),
            GitLabCI(; coverage=false, extra_versions=[v"0.6"]),
            License(; name="ISC"),
            ProjectFile(; version=v"1"),
            Readme(; inline_badges=true),
            TagBot(;
                cron="0 0 */3 * *",
                token=Secret("MYTOKEN"),
                ssh=Secret("SSHKEY"),
                ssh_password=Secret("SSHPASS"),
                changelog="Line 1\nLine 2\n\nLine 4",
                changelog_ignore=["foo", "bar"],
                gpg=Secret("GPGKEY"),
                gpg_password=Secret("GPGPASS"),
                registry="Foo/Bar",
                branches=false,
                dispatch=true,
                dispatch_delay=20,
            ),
            Tests(; project=true),
            TravisCI(;
                coverage=false,
                windows=false,
                x86=true,
                arm64=true,
                extra_versions=["1.1"],
            ),
        ])
    end
end
