t = Template(; user=me)
pkg_dir = joinpath(t.dir, test_pkg)

@testset "CITATION" begin
    @testset "Plugin creation" begin
        p = Citation()
        @test isempty(p.gitignore)
        @test p.dest == "CITATION.bib"
        @test isempty(p.badges)
        @test isempty(p.view)
        @test !p.readme_section
        p = Citation(; readme_section=true)
        @test p.readme_section
    end

    @testset "File generation" begin
        # Without a coverage plugin in the template, there should be no post-test step.
        p = Citation()
        @test gen_plugin(p, t, test_pkg) == ["CITATION.bib"]
        @test isfile(joinpath(pkg_dir, "CITATION.bib"))
        citation = read(joinpath(pkg_dir, "CITATION.bib"), String)

        @test occursin("@misc", citation)
        @test occursin("$(t.authors)", citation)
        @test occursin("v0.0.1", citation)
    end

    @testset "Readme modification" begin
        p = Citation(; readme_section=true)
        t.plugins[Citation] = p
        isdir(pkg_dir) && rm(pkg_dir; recursive=true)
        generate(test_pkg, t, git=false)
        readme = read(joinpath(pkg_dir, "README.md"), String)
        @test occursin("## Citing", readme)
        @test occursin("CITATION.bib", readme)
    end
end

rm(pkg_dir; recursive=true)
