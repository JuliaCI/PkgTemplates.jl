# Don't move this line from the top, please. {{X}} {{Y}} {{Z}}

@info "Running plugin tests"

struct FileTest <: PT.FilePlugin
    a::String
    b::Bool
end

PT.gitignore(::FileTest) = ["a", "aa", "aaa"]
PT.source(::FileTest) = @__FILE__
PT.destination(::FileTest) = "foo.txt"
PT.badges(::FileTest) = PT.Badge("{{X}}", "{{Y}}", "{{Z}}")
PT.view(::FileTest, ::Template, ::AbstractString) = Dict("X" => 0, "Y" => 2)
PT.user_view(::FileTest, ::Template, ::AbstractString) = Dict("X" => 1, "Z" => 3)

@testset "Plugins" begin
    @testset "FilePlugin" begin
        p = FileTest("foo", true)
        t = tpl(; plugins=[p])

        # The X from user_view should override the X from view.
        s = PT.render_plugin(p, t, "")
        @test occursin("1 2 3", first(split(s, "\n")))

        with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            badge = string(PT.Badge("1", "2", "3"))
            @test occursin("a\naa\naaa", read(joinpath(pkg_dir, ".gitignore"), String))
            @test occursin(badge, read(joinpath(pkg_dir, "README.md"), String))
            @test read(joinpath(pkg_dir, "foo.txt"), String) == s
        end
    end

    @testset "Tests Project.toml warning on Julia < 1.2" begin
        p = Tests(; project=true)
        @test_logs (:warn, r"The project option is set") tpl(; julia=v"1", plugins=[p])
        @test_logs (:warn, r"The project option is set") tpl(; julia=v"1.1", plugins=[p])
        @test_logs tpl(; julia=v"1.2", plugins=[p])
        @test_logs tpl(; julia=v"1.3", plugins=[p])
    end

    @testset "CI versions" begin
        t = tpl(; julia=v"1")
        @test PT.collect_versions(t, ["1.0", "1.5", "nightly"]) == ["1.0", "1.5", "nightly"]
        t = tpl(; julia=v"2")
        @test PT.collect_versions(t, ["1.0", "1.5", "nightly"]) == ["2.0", "nightly"]
    end

    @testset "Equality" begin
        a = FileTest("foo", true)
        b = FileTest("foo", true)
        @test a == b
        c = FileTest("foo", false)
        @test a != c
    end
end
