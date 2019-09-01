# Don't move this line from the top, please. {{X}} {{Y}} {{Z}}

struct BasicTest <: PT.BasicPlugin end

PT.gitignore(::BasicTest) = ["a", "aa", "aaa"]
PT.source(::BasicTest) = @__FILE__
PT.destination(::BasicTest) = "foo.txt"
PT.badges(::BasicTest) = PT.Badge("{{X}}", "{{Y}}", "{{Z}}")
PT.view(::BasicTest, ::Template, ::AbstractString) = Dict("X" => 0, "Y" => 2)
PT.user_view(::BasicTest, ::Template, ::AbstractString) = Dict("X" => 1, "Z" => 3)

@testset "BasicPlugin" begin
    p = BasicTest()
    t = tpl(; plugins=[p])

    # The X from user_view should override the X from view.
    s = PT.render_plugin(p, t, "")
    @test occursin("1 2 3", first(split(s, "\n")))

    with_pkg(t) do pkg
        pkg_dir = joinpath(t.dir, pkg)
        badge = string(PT.Badge("1", "2", "3"))
        @test occursin(badge, read(joinpath(pkg_dir, "README.md"), String))
        observed = read(joinpath(pkg_dir, "foo.txt"), String)
        # On Travis, everything works with CRLF.
        Sys.iswindows() && (observed = replace(observed, "\r\n" => "\n"))
        @test observed == s
    end
end
