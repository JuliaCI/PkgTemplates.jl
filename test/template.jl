@testset "Template" begin
    @testset "Template constructor" begin
        @testset "user" begin
            if isempty(PT.default_user())
                @test_throws ArgumentError Template()
                haskey(ENV, "CI") && run(`git config --global github.user $USER`)
            end
            @test Template().user == PT.default_user()
        end

        @testset "authors" begin
            @test tpl(; authors=["a"]).authors == ["a"]
            @test tpl(; authors="a").authors == ["a"]
            @test tpl(; authors="a,b").authors == ["a", "b"]
            @test tpl(; authors="a, b").authors == ["a", "b"]
        end

        @testset "host" begin
            @test tpl(; host="https://foo.com").host == "foo.com"
        end

        @testset "dir" begin
            @test tpl(; dir="/foo/bar").dir == joinpath(path_separator, "foo", "bar")
            @test tpl(; dir="foo").dir == abspath("foo")
            @test tpl(; dir="~/foo").dir == abspath(expanduser("~/foo"))
        end

        @testset "plugins / disabled_defaults" begin
            function test_plugins(plugins, expected, disabled=DataType[])
                t = tpl(; plugins=plugins, disable_defaults=disabled)
                @test issetequal(values(t.plugins), expected)
            end

            defaults = PT.default_plugins()
            test_plugins([], defaults)
            test_plugins([Citation()], union(defaults, [Citation()]))
            # Overriding a default plugin.
            gi = Gitignore(; dev=false)
            test_plugins([gi], union(setdiff(defaults, [Gitignore()]), [gi]))
            # Disabling a default plugin.
            test_plugins([], setdiff(defaults, [Gitignore()]), [Gitignore])
        end
    end

    @testset "hasplugin" begin
        t = tpl(; plugins=[Documenter{TravisCI}()])
        @test PT.hasplugin(t, typeof(first(PT.default_plugins())))
        @test PT.hasplugin(t, Documenter)
        @test PT.hasplugin(t, _ -> true)
        @test !PT.hasplugin(t, _ -> false)
        @test !PT.hasplugin(t, Citation)
        @test !PT.hasplugin(t, PT.is_ci)
    end
end

@context ErrorOnRepoInit
function Cassette.prehook(::ErrorOnRepoInit, ::typeof(LibGit2.init), pkg_dir)
    @test isdir(pkg_dir)
    error()
end

@testset "Package generation errors" begin
    mktempdir() do dir
        t = tpl(; dir=dirname(dir))
        @test_throws ArgumentError t(basename(dir))
    end

    mktemp() do f, _io
        t = tpl(; dir=dirname(f))
        @test_throws ArgumentError t(basename(f))
    end

    t = tpl()
    pkg = pkgname()
    @test_throws ErrorException @overdub ErrorOnRepoInit() @suppress t(pkg)
    @test !isdir(joinpath(t.dir, pkg))
end
