using Base.Filesystem: path_separator

using LibGit2: LibGit2, GitCommit, GitRemote, GitRepo
using Pkg: Pkg
using Random: Random
using Test: @test, @testset, @test_throws

using Cassette: Cassette, @context, @overdub
using ReferenceTests: @test_reference
using Suppressor: @suppress

using PkgTemplates
const PT = PkgTemplates

const USER = "tester"

Random.seed!(1)

# Creata a template that won't error because of a missing username.
tpl(; kwargs...) = Template(; user=USER, kwargs...)

const pkg_name = Ref("A")

# Generate an unused package name.
pkgname() = pkg_name[] *= "a"

# Create a randomly named package with a template, and delete it afterwards.
function with_pkg(f::Function, t::Template, pkg::AbstractString=pkgname())
    @suppress t(pkg)
    try
        f(pkg)
    finally
        haskey(Pkg.installed(), pkg) && @suppress Pkg.rm(pkg)
        rm(joinpath(t.dir, pkg); recursive=true, force=true)
    end
end

mktempdir() do dir
    Pkg.activate(dir)
    pushfirst!(DEPOT_PATH, dir)
    try
        @testset "PkgTemplates.jl" begin
            include("template.jl")
            include("plugin.jl")
            include("git.jl")

            # Quite a bit of output depends on the Julia version,
            # and the test fixtures are made with Julia 1.2.
            # TODO: Keep this on the latest stable Julia version.
            if VERSION.major == 1 && VERSION.minor == 2
                include("reference.jl")
            else
                @info "Skipping reference tests" julia=VERSION
            end
        end
    finally
        popfirst!(DEPOT_PATH)
    end
end
