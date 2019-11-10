const STATIC_FILE = joinpath(@__DIR__, "fixtures", "static.txt")

PT.user_view(::Citation, ::Template, ::AbstractString) = Dict("MONTH" => 8, "YEAR" => 2019)
PT.user_view(::License, ::Template, ::AbstractString) = Dict("YEAR" => 2019)

function test_all(pkg::AbstractString; kwargs...)
    t = tpl(; kwargs...)
    with_pkg(t, pkg) do pkg
        pkg_dir = joinpath(t.dir, pkg)
        foreach(readlines(`git -C $pkg_dir ls-files`)) do f
            reference = joinpath(@__DIR__, "fixtures", pkg, f)
            observed = read(joinpath(pkg_dir, f), String)
            @test_reference reference observed
        end
    end
end

@testset "Reference tests" begin
    @testset "Default package" begin
        test_all("Basic"; authors=USER)
    end

    @testset "All plugins" begin
        test_all("AllPlugins"; authors=USER, plugins=[
            AppVeyor(), CirrusCI(), Citation(), Codecov(), Coveralls(), Develop(),
            Documenter(), DroneCI(), GitHubActions(), GitLabCI(), TravisCI(),
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
        test_all("WackyOptions"; authors=USER, julia=v"1.2", plugins=[
            AppVeyor(; x86=true, coverage=true, extra_versions=[v"1.3"]),
            CirrusCI(; image="freebsd-123", coverage=false, extra_versions=["1.1"]),
            Citation(; readme=true),
            Codecov(; file=STATIC_FILE),
            Coveralls(; file=STATIC_FILE),
            Documenter{GitLabCI}(
                assets=[STATIC_FILE],
                makedocs_kwargs=Dict(:foo => "bar", :bar => "baz"),
                canonical_url=(_t, _pkg) -> "http://example.com",
            ),
            DroneCI(; amd64=false, arm=true, arm64=true, extra_versions=["1.1"]),
            Git(; ignore=["a", "b", "c"], manifest=true),
            GitHubActions(; x86=true, linux=false, coverage=false),
            GitLabCI(; coverage=false, extra_versions=[v"0.6"]),
            License(; name="ISC"),
            ProjectFile(; version=v"1"),
            Readme(; inline_badges=true),
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
