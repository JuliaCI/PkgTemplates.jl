@context PTIsInstalled
function Cassette.posthook(::PTIsInstalled, result::Dict, ::typeof(Pkg.installed))
    result["PkgTemplates"] = v"1.2.3"
    return result
end

@testset "Git repositories" begin
    @testset "Does not create Git repo" begin
        t = tpl(; git=false)
        with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            @test !isdir(joinpath(pkg_dir, ".git"))
        end
    end

    @testset "Creates Git repo" begin
        t = tpl(; git=true)
        with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            @test isdir(joinpath(pkg_dir, ".git"))
        end
    end

    @testset "With HTTPS" begin
        t = tpl(; git=true, ssh=false)
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                remote = LibGit2.get(GitRemote, repo, "origin")
                @test startswith(LibGit2.url(remote), "https://")
            end
        end
    end

    @testset "With SSH" begin
        t = tpl(; git=true, ssh=true)
        with_pkg(t) do pkg
            LibGit2.with(GitRepo(joinpath(t.dir, pkg))) do repo
                remote = LibGit2.get(GitRemote, repo, "origin")
                @test startswith(LibGit2.url(remote), "git@")
            end
        end
    end

    @testset "Adds version to commit message" begin
        # We're careful to avoid a Pkg.update as it triggers Cassette#130.
        t = tpl(; git=true, develop=false, disable_defaults=[Tests])
        @overdub PTIsInstalled() with_pkg(t) do pkg
            pkg_dir = joinpath(t.dir, pkg)
            LibGit2.with(GitRepo(pkg_dir)) do repo
                commit = GitCommit(repo, "HEAD")
                @test occursin("PkgTemplates version: 1.2.3", LibGit2.message(commit))
            end
        end
    end
end
