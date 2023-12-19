@info "Running template tests"

@testset "Template" begin
    @testset "Template constructor" begin
        @testset "user" begin
            msg = sprint(showerror, PT.MissingUserException{TravisCI}())
            @test startswith(msg, "TravisCI: ")

            patch = @patch PkgTemplates.getkw!(kwargs, k) = ""
            apply(patch) do
                @test_throws PT.MissingUserException Template()
                @test isempty(Template(; plugins=[!Git, !GitHubActions]).user)
            end

            patch = @patch PkgTemplates.getkw!(kwargs, k) = "username"
            apply(patch) do
                @test Template().user == "username"
            end
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

        @testset "plugins" begin
            function test_plugins(plugins, expected)
                t = tpl(; plugins=plugins)
                @test all(map(==, sort(t.plugins; by=string), sort(expected; by=string)))
            end

            defaults = PT.default_plugins()
            test_plugins([], defaults)
            test_plugins([Citation()], union(defaults, [Citation()]))

            # Overriding a default plugin.
            default_g = defaults[findfirst(p -> p isa Git, defaults)]
            g = Git(; ssh=true)
            test_plugins([g], union(setdiff(defaults, [default_g]), [g]))

            # Disabling a default plugin.
            test_plugins([!Git], setdiff(defaults, [default_g]))

            # Duplicated default plugins are supported
            g2 = Git(; branch="foo")
            test_plugins([g, g2], union(setdiff(defaults, [default_g]), [g, g2]))

            # Duplicated non-default plugins are supported
            c1 = Citation()
            c2 = Citation()
            test_plugins([c1, c2], vcat(defaults, [c1, c2]))
        end

        @testset "Unsupported keywords warning" begin
            @test_logs tpl()
            @test_logs (:warn, r"Unrecognized keywords were supplied") tpl(; x=1, y=2)
        end
    end

    @testset "Equality" begin
        a = tpl()
        b = tpl()
        @test a == b
        c = tpl(julia=v"0.3")
        @test a != c
    end

    @testset "hasplugin" begin
        t = tpl(; plugins=[TravisCI(), Documenter{TravisCI}()])
        @test PT.hasplugin(t, typeof(first(PT.default_plugins())))
        @test PT.hasplugin(t, Documenter)
        @test PT.hasplugin(t, PT.is_ci)
        @test PT.hasplugin(t, _ -> true)
        @test !PT.hasplugin(t, _ -> false)
        @test !PT.hasplugin(t, Citation)
    end

    @testset "validate" begin
        foreach((GitHubActions, TravisCI, GitLabCI)) do T
            @test_throws ArgumentError tpl(; plugins=[!GitHubActions, Documenter{T}()])
        end

        patch = @patch LibGit2.getconfig(r, n) = ""
        apply(patch) do
            @test_throws ArgumentError tpl(; plugins=[Git()])
        end
    end
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

    patch = @patch LibGit2.init(pkg_dir) = error()
    apply(patch) do
        @test_throws ErrorException @suppress t(pkg)
    end
    @test !isdir(joinpath(t.dir, pkg))

    mktempdir() do dir
        t = tpl(; dir=dir)
        @test_throws ArgumentError t("42Foo.jl")
        @test_throws ArgumentError t("42Foo")
        @test_throws ArgumentError t("Foo Bar.jl")
        @test_throws ArgumentError t("Foo Bar")
    end
end
