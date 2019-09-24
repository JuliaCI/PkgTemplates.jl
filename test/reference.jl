function PT.user_view(::Citation, ::Template, ::AbstractString)
    return Dict("MONTH" => 8, "YEAR" => 2019)
end

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
        test_all("Basic"; authors=USER, manifest=true)
    end

    @testset "All plugins" begin
        test_all("AllPlugins"; authors=USER, manifest=true, plugins=[
            AppVeyor(), CirrusCI(), Citation(), Codecov(), Coveralls(),
            Develop(), Documenter(), GitLabCI(), TravisCI(),
        ])
    end

    @testset "Wacky options" begin
        # TODO
    end
end
