# TODO: License fixtures need to be updated every year because they don't use Mustache.

function PT.user_view(::Citation, ::Template, ::AbstractString)
    return Dict("MONTH" => 8, "YEAR" => 2019)
end

function test_all(pkg::AbstractString; kwargs...)
    t = tpl(; kwargs...)
    pkg_dir = joinpath(t.dir, pkg)
    t(pkg)
    try
        foreach(readlines(`git -C $pkg_dir ls-files`)) do f
            # All fixture files are .txt so that ReferenceTests can't handle them.
            reference = joinpath(@__DIR__, "fixtures", pkg, f * ".txt")
            observed = read(joinpath(pkg_dir, f), String)
            @test_reference reference observed
        end
    finally
        rm(pkg_dir; recursive=true, force=true)
    end
end

@testset "Default package" begin
    test_all("Basic"; authors=USER, develop=false, manifest=true)
end

@testset "All plugins" begin
    test_all("AllPlugins"; authors=USER, develop=false, manifest=true, plugins=[
        AppVeyor(), CirrusCI(), Citation(), Codecov(),
        Coveralls(), Documenter(), GitLabCI(), TravisCI(),
    ])
end
