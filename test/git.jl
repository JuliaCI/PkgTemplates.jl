@info "Running Git tests"

@testset "Git repositories" begin
    @testset "Does not create Git repo" begin
        t = tpl(; plugins=[!Git])
        with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            @test !isdir(joinpath(pkg_dir, ".git"))
        end
    end

    @testset "Creates Git repo" begin
        t = tpl(; plugins=[Git()])
        with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            @test isdir(joinpath(pkg_dir, ".git"))
        end
    end

    @testset "With HTTPS" begin
        t = tpl(; plugins=[Git(; ssh=false)])
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                remote = LibGit2.get(GitRemote, repo, "origin")
                @test startswith(LibGit2.url(remote), "https://")
            end
        end
    end

    @testset "With SSH" begin
        t = tpl(; plugins=[Git(; ssh=true)])
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                remote = LibGit2.get(GitRemote, repo, "origin")
                @test startswith(LibGit2.url(remote), "git@")
            end
        end
    end

    @testset "Without .jl suffix" begin
        t = tpl(; plugins=[Git(; jl=false)])
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                remote = LibGit2.get(GitRemote, repo, "origin")
                @test !occursin(".jl", LibGit2.url(remote))
            end
        end
    end

    @testset "With custom name/email" begin
        t = tpl(; plugins=[Git(; name="me", email="a@b.c")])
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                @test LibGit2.getconfig(repo, "user.name", "") == "me"
                @test LibGit2.getconfig(repo, "user.email", "") == "a@b.c"
            end
        end
    end

    @testset "With custom default branch" begin
        t = tpl(; plugins=[Git(; branch="main")])
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                @test LibGit2.branch(repo) == "main"
            end
        end
    end

    @testset "Adds version to commit message" begin
        # We're careful to avoid a Pkg.update as it triggers Cassette#130.
        t = tpl(; plugins=[Git(), !Tests])
        mock(PT.version_of => _p -> v"1.2.3") do _i
            with_pkg(t) do pkg
                pkg_dir = joinpath(t.dir, pkg)
                LibGit2.with(GitRepo(pkg_dir)) do repo
                    commit = GitCommit(repo, "HEAD")
                    @test occursin("PkgTemplates version: 1.2.3", LibGit2.message(commit))
                end
            end
        end
    end
end
