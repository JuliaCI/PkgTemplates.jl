@info "Running template tests"

@testset verbose = true "Template" begin
    @testset verbose = true "Template constructor" begin
        @testset verbose = true "user" begin
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

        @testset verbose = true "authors" begin
            @test tpl(; authors=["a"]).authors == ["a"]
            @test tpl(; authors="a").authors == ["a"]
            @test tpl(; authors="a,b").authors == ["a", "b"]
            @test tpl(; authors="a, b").authors == ["a", "b"]
        end

        @testset verbose = true "host" begin
            @test tpl(; host="https://foo.com").host == "foo.com"
        end

        @testset verbose = true "dir" begin
            @test tpl(; dir="/foo/bar").dir == joinpath(path_separator, "foo", "bar")
            @test tpl(; dir="foo").dir == abspath("foo")
            @test tpl(; dir="~/foo").dir == abspath(expanduser("~/foo"))
        end

        @testset verbose = true "plugins" begin
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
        end

        @testset verbose = true "Unsupported keywords warning" begin
            @test_logs tpl()
            @test_logs (:warn, r"Unrecognized keywords were supplied") tpl(; x=1, y=2)
        end
    end

    @testset verbose = true "Equality" begin
        a = tpl()
        b = tpl()
        @test a == b
        c = tpl(julia=v"0.3")
        @test a != c
    end

    @testset verbose = true "hasplugin" begin
        t = tpl(; plugins=[TravisCI(), Documenter{TravisCI}()])
        @test PT.hasplugin(t, typeof(first(PT.default_plugins())))
        @test PT.hasplugin(t, Documenter)
        @test PT.hasplugin(t, PT.is_ci)
        @test PT.hasplugin(t, _ -> true)
        @test !PT.hasplugin(t, _ -> false)
        @test !PT.hasplugin(t, Citation)
    end

    @testset verbose = true "validate" begin
        foreach((GitHubActions, TravisCI, GitLabCI)) do T
            @test_throws ArgumentError tpl(; plugins=[!GitHubActions, Documenter{T}()])
        end

        patch = @patch LibGit2.getconfig(r, n) = ""
        apply(patch) do
            @test_throws ArgumentError tpl(; plugins=[Git()])
        end
    end
end

@testset verbose = true "Package generation errors" begin
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
end
