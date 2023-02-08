using Base: UUID, contractuser
using Base.Filesystem: path_separator

using LibGit2: LibGit2, GitCommit, GitRemote, GitRepo
using Pkg: Pkg, PackageSpec, TOML
using Random: Random, randstring
using Test: @test, @testset, @test_broken, @test_logs, @test_throws
using UUIDs: uuid4

using DeepDiffs: deepdiff
using Mocking
using Suppressor: @suppress

using PkgTemplates

Mocking.activate()

const PT = PkgTemplates
const USER = "tester"

Random.seed!(1)

# Creata a template that won't error because of a missing username.
tpl(; kwargs...) = Template(; user=USER, kwargs...)

# Generate a random package name.
pkgname() = titlecase(randstring('A':'Z', 16))

# Create a randomly named package with a template, and delete it afterwards.
function with_pkg(f::Function, t::Template, pkg::AbstractString=pkgname())
    patch = @patch uuid4() = UUID("c51a4d33-e9a4-4efb-a257-e0de888ecc28")
    @suppress apply(patch) do
        t(pkg)
    end
    try
        f(pkg)
    finally
        # On 1.4, this sometimes won't work, but the error is that the package isn't installed.
        # We're going to delete the package directory anyways, so just ignore any errors.
        PT.version_of(pkg) === nothing || try @suppress Pkg.rm(pkg) catch; end
        rm(joinpath(t.dir, pkg); recursive=true, force=true)
    end
end

function print_diff(a, b)
    old = Base.have_color
    @eval Base have_color = true
    try
        println(deepdiff(a, b))
    finally
        @eval Base have_color = $old
    end
end

# LibGit2 doesn't respect the $GIT_CONFIG environment variable,
# but we need to use it to avoid modifying the user's environment.
function with_clean_gitconfig(f)
    function getconfig(key, default)
        try
            readchomp(`git config --get $key`)
        catch
            default
        end
    end
    patch = @patch LibGit2.getconfig(key, default) = getconfig(key, default)
    if !Sys.iswindows()
        mktemp() do file, _io
            withenv("GIT_CONFIG" => file) do
                apply(patch) do
                    f()
                end
            end
        end
    else
        # Windows gives a permission error if an external command like `git` tries
        # to write to the file while Julia holds the `_io` handle.
        # So we use the less-safe tempname approach.
        file = touch(tempname())
        withenv("GIT_CONFIG" => file) do
            apply(patch) do
                f()
            end
        end
        rm(file)
    end
end


mktempdir() do dir
    Pkg.activate(dir)
    pushfirst!(DEPOT_PATH, dir)
    try
        @testset "PkgTemplates.jl" begin
            include("template.jl")
            include("plugin.jl")
            include("show.jl")

            if VERSION < v"1.8"
                # Interactive tests disabled on Julia Version >= 1.8 due to:
                # https://github.com/JuliaCI/PkgTemplates.jl/issues/370
                include("interactive.jl")
            else
                @info "Skipping interactive tests (requiring <v\"1.8\")" VERSION
            end

            if PT.git_is_installed()
                include("git.jl")

                # Quite a bit of output depends on the Julia version,
                # and the test fixtures are made with Julia 1.7.
                # TODO: Keep this on the latest stable Julia version, and update
                # the version used by the corresponding CI job at the same time.
                REFERENCE_VERSION = v"1.7.2"
                if VERSION == REFERENCE_VERSION
                    # Ideally we'd use `with_clean_gitconfig`, but it's way too slow.
                    branch = LibGit2.getconfig(
                        "init.defaultBranch",
                        PT.DEFAULT_DEFAULT_BRANCH,
                    )
                    if branch == PT.DEFAULT_DEFAULT_BRANCH
                        include("reference.jl")
                    else
                        "Skipping reference tests, init.defaultBranch is set"
                    end
                else
                    @info "Skipping reference tests (requiring $REFERENCE_VERSION)" VERSION
                end
            else
                @info "Git is not installed, skipping Git and reference tests"
            end
        end
    finally
        popfirst!(DEPOT_PATH)
    end
end
