const TEST_UUID = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
const TEST_DEP = PackageSpec(; name="Test", uuid=TEST_UUID)

badge_order() = [
    Documenter{GitLabCI},
    Documenter{TravisCI},
    GitLabCI,
    TravisCI,
    AppVeyor,
    CirrusCI,
    Codecov,
    Coveralls,
]

"""
    ProjectFile()

Creates a `Project.toml`.
"""
struct ProjectFile <: Plugin end

# Create Project.toml in the prehook because other hooks might depend on it.
function prehook(::ProjectFile, t::Template, pkg_dir::AbstractString)
    toml = Dict(
        "name" => basename(pkg_dir),
        "uuid" => uuid4(),
        "authors" => t.authors,
        "compat" => Dict("julia" => compat_version(t.julia_version)),
    )
    open(io -> TOML.print(io, toml), joinpath(pkg_dir, "Project.toml"), "w")
end

"""
    compat_version(v::VersionNumber) -> String

Format a `VersionNumber` to exclude trailing zero components.
"""
function compat_version(v::VersionNumber)
    return if v.patch == 0 && v.minor == 0
        "$(v.major)"
    elseif v.patch == 0
        "$(v.major).$(v.minor)"
    else
        "$(v.major).$(v.minor).$(v.patch)"
    end
end

"""
    SrcDir(; file="$(contractuser(default_file("src", "module.jl")))")

Creates a module entrypoint.
"""
@with_kw_noshow mutable struct SrcDir <: BasicPlugin
    file::String = default_file("src", "module.jl")
    destination::String = joinpath("src", "<module>.jl")
end

# Don't display the destination field.
function Base.show(io::IO, ::MIME"text/plain", p::SrcDir)
    indent = get(io, :indent, 0)
    print(io, repeat(' ', indent), "SrcDir:")
    print(io, "\n", repeat(' ', indent + 2), "file: ", show_field(p.file))
end

source(p::SrcDir) = p.file
destination(p::SrcDir) = p.destination
view(::SrcDir, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

# Update the destination now that we know the package name.
# Kind of hacky, but oh well.
function prehook(p::SrcDir, t::Template, pkg_dir::AbstractString)
    invoke(prehook, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)
    p.destination = joinpath("src", basename(pkg_dir) * ".jl")
end

"""
    Readme(;
        file="$(contractuser(default_file("README.md")))",
        destination="README.md",
        inline_badges=false,
    )

Creates a `README` file.
By default, it includes badges for other included plugins

## Keyword Arguments
- `file::AbstractString`: Template file for the `README`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, values of `"README"` or `"README.rst"` might be desired.
- `inline_badges::Bool`: Whether or not to put the badges on the same line as the package name.
"""
@with_kw_noshow struct Readme <: BasicPlugin
    file::String = default_file("README.md")
    destination::String = "README.md"
    inline_badges::Bool = false
end

source(p::Readme) = p.file
destination(p::Readme) = p.destination

function view(p::Readme, t::Template, pkg::AbstractString)
    # Explicitly ordered badges go first.
    strings = String[]
    done = DataType[]
    foreach(badge_order()) do T
        if hasplugin(t, T)
            bs = badges(t.plugins[T], t, pkg)
            append!(strings, badges(t.plugins[T], t, pkg))
            push!(done, T)
        end
    end
    foreach(setdiff(keys(t.plugins), done)) do T
        bs = badges(t.plugins[T], t, pkg)
        append!(strings, badges(t.plugins[T], t, pkg))
    end

    return Dict(
        "BADGES" => strings,
        "HAS_CITATION" => hasplugin(t, Citation) && t.plugins[Citation].readme,
        "HAS_INLINE_BADGES" => !isempty(strings) && p.inline_badges,
        "PKG" => pkg,
    )
end

"""
    License(; name="MIT", path=nothing, destination="LICENSE")

Creates a license file.

## Keyword Arguments
- `name::AbstractString`: Name of a license supported by PkgTemplates.
  Available licenses can be seen [here](https://github.com/invenia/PkgTemplates.jl/tree/master/templates/licenses).
- `path::Union{AbstractString, Nothing}`: Path to a custom license file.
  This keyword takes priority over `name`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, `"LICENSE.md"` might be desired.
"""
struct License <: BasicPlugin
    path::String
    destination::String
end

function License(
    name::AbstractString="MIT",
    path::Union{AbstractString, Nothing}=nothing,
    destination::AbstractString="LICENSE",
)
    if path === nothing
        path = default_file("licenses", name)
        isfile(path) || throw(ArgumentError("License '$(basename(path))' is not available"))
    end
    return License(path, destination)
end


source(p::License) = p.path
destination(p::License) = p.destination
view(::License, t::Template, ::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "YEAR" => year(today()),
)

"""
    Git(; ignore=String[], ssh=false, manifest=false, gpgsign=false)

Creates a Git repository and a `.gitignore` file.

## Keyword Arguments
- `ignore::Vector{<:AbstractString}`: Patterns to add to the `.gitignore`.
  See also: [`gitignore`](@ref).
- `ssh::Bool`: Whether or not to use SSH for the remote.
  If left unset, HTTPS is used.
- `manifest::Bool`: Whether or not to commit `Manifest.toml`.
- `gpgsign::Bool`: Whether or not to sign commits with your GPG key.
  This option requires that the Git CLI is installed.
"""
@with_kw_noshow struct Git <: Plugin
    ignore::Vector{String} = []
    ssh::Bool = false
    manifest::Bool = false
    gpgsign::Bool = false
end

gitignore(p::Git) = p.ignore

# Set up the Git repository.
function prehook(p::Git, t::Template, pkg_dir::AbstractString)
    if p.gpgsign && try run(pipeline(`git --version`; stdout=devnull)); false catch; true end
        throw(ArgumentError("Git: gpgsign is set but the Git CLI is not installed"))
    end
    LibGit2.with(LibGit2.init(pkg_dir)) do repo
        commit(p, repo, pkg_dir, "Initial commit")
        pkg = basename(pkg_dir)
        url = if p.ssh
            "git@$(t.host):$(t.user)/$pkg.jl.git"
        else
            "https://$(t.host)/$(t.user)/$pkg.jl"
        end
        LibGit2.with(GitRemote(repo, "origin", url)) do remote
            # TODO: `git pull` still requires some Git branch config.
            LibGit2.add_push!(repo, remote, "refs/heads/master")
        end
    end
end

# Create the .gitignore.
function hook(p::Git, t::Template, pkg_dir::AbstractString)
    gen_file(joinpath(pkg_dir, ".gitignore"), render_plugin(p, t))
end

# Commit the files
function posthook(p::Git, t::Template, pkg_dir::AbstractString)
    # Ensure that the manifest exists if it's going to be committed.
    manifest = joinpath(pkg_dir, "Manifest.toml")
    if p.manifest && !isfile(manifest)
        touch(manifest)
        with_project(Pkg.update, pkg_dir)
    end

    LibGit2.with(GitRepo(pkg_dir)) do repo
        LibGit2.add!(repo, ".")
        msg = "Files generated by PkgTemplates"
        installed = Pkg.installed()
        if haskey(installed, "PkgTemplates")
            ver = string(installed["PkgTemplates"])
            msg *= "\n\nPkgTemplates version: $ver"
        end
        commit(p, repo, pkg_dir, msg)
    end
end

function commit(p::Git, repo::GitRepo, pkg_dir::AbstractString, msg::AbstractString)
    if p.gpgsign
        run(pipeline(`git -C $pkg_dir commit -S --allow-empty -m $msg`; stdout=devnull))
    else
        LibGit2.commit(repo, msg)
    end
end

function render_plugin(p::Git, t::Template)
    ignore = mapreduce(gitignore, append!, values(t.plugins))
    # Only ignore manifests at the repo root.
    p.manifest || "Manifest.toml" in ignore || push!(ignore, "/Manifest.toml")
    unique!(sort!(ignore))
    return join(ignore, "\n")
end

"""
    Tests(; file="$(contractuser(default_file("test", "runtests.jl")))", project=false)

Sets up testing for packages.

## Keyword Arguments
- `file::AbstractString`: Template file for the `runtests.jl`.
- `project::Bool`: Whether or not to create a new project for tests (`test/Project.toml`).
  See [here](https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1) for more details.

!!! note
    Managing test dependencies with `test/Project.toml` is only supported in Julia 1.2 and later.
"""
@with_kw_noshow struct Tests <: BasicPlugin
    file::String = default_file("test", "runtests.jl")
    project::Bool = false
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")
view(::Tests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

function prehook(p::Tests, t::Template, pkg_dir::AbstractString)
    invoke(prehook, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)
    p.project && t.julia_version < v"1.2" && @warn string(
        "Tests: The project option is set to create a project (supported in Julia 1.2 and later) ",
        "but a Julia version older than 1.2 is supported by the Template.",
    )
end


function hook(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal BasicPlugin behaviour to create the test script.
    invoke(hook, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)

    # Then set up the test depdendency in the chosen way.
    f = p.project ? make_test_project : add_test_dependency
    f(pkg_dir)
end

# Create a new test project.
function make_test_project(pkg_dir::AbstractString)
    with_project(() -> Pkg.add(TEST_DEP), joinpath(pkg_dir, "test"))
end

# Add Test as a test-only dependency.
function add_test_dependency(pkg_dir::AbstractString)
    # Add the dependency manually since there's no programmatic way to add to [extras].
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    get!(toml, "extras", Dict())["Test"] = TEST_UUID
    get!(toml, "targets", Dict())["test"] = ["Test"]
    open(io -> TOML.print(io, toml), path, "w")

    # Generate the manifest by updating the project.
    # This also ensures that keys in Project.toml are sorted properly.
    touch(joinpath(pkg_dir, "Manifest.toml"))  # File must exist to be modified by Pkg.
    with_project(Pkg.update, pkg_dir)
end
