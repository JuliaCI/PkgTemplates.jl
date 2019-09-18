const TEST_UUID = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
const TEST_DEP = PackageSpec(; name="Test", uuid=TEST_UUID)
const LICENSE_DIR = normpath(joinpath(@__DIR__, "..", "..", "licenses"))
const LICENSES = Dict(
    "MIT" => "MIT \"Expat\" License",
    "BSD2" => "Simplified \"2-clause\" BSD License",
    "BSD3" => "Modified \"3-clause\" BSD License",
    "ISC" => "Internet Systems Consortium License",
    "ASL" => "Apache License, Version 2.0",
    "MPL" => "Mozilla Public License, Version 2.0",
    "GPL-2.0+" => "GNU Public License, Version 2.0+",
    "GPL-3.0+" => "GNU Public License, Version 3.0+",
    "LGPL-2.1+" => "Lesser GNU Public License, Version 2.1+",
    "LGPL-3.0+" => "Lesser GNU Public License, Version 3.0+",
    "EUPL-1.2+" => "European Union Public Licence, Version 1.2+",
)

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
    License(; name="MIT", destination="LICENSE")

Creates a license file.

## Keyword Arguments
- `name::AbstractString`: Name of the desired license.
  Available licenses can be seen [here](https://github.com/invenia/PkgTemplates.jl/tree/master/licenses).
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, `"LICENSE.md"` might be desired.
"""
struct License <: Plugin
    path::String
    destination::String

    function License(name::AbstractString="MIT", destination::AbstractString="LICENSE")
        return new(license_path(name), destination)
    end
end

# Look up a license and throw an error if it doesn't exist.
function license_path(license::AbstractString)
    path = joinpath(LICENSE_DIR, license)
    isfile(path) || throw(ArgumentError("License '$license' is not available"))
    return path
end

function render_plugin(p::License, t::Template)
    date = year(today())
    authors = join(t.authors, ", ")
    text = "Copyright (c) $date $authors\n\n"
    license = strip(read(p.path, String))
    return text * license
end

function gen_plugin(p::License, t::Template, pkg_dir::AbstractString)
    gen_file(joinpath(pkg_dir, p.destination), render_plugin(p, t))
end

"""
    Gitignore(; ds_store=true, dev=true)

Creates a `.gitignore` file.

## Keyword Arguments
- `ds_store::Bool`: Whether or not to ignore MacOS's `.DS_Store` files.
- `dev::Bool`: Whether or not to ignore the directory of locally-developed packages.
"""
@with_kw_noshow struct Gitignore <: Plugin
    ds_store::Bool = true
    dev::Bool = true
end

function render_plugin(p::Gitignore, t::Template)
    init = String[]
    p.ds_store && push!(init, ".DS_Store")
    p.dev && push!(init, "/dev/")
    entries = mapreduce(gitignore, append!, values(t.plugins); init=init)
    # Only ignore manifests at the repo root.
    t.manifest || "Manifest.toml" in entries || push!(entries, "/Manifest.toml")
    unique!(sort!(entries))
    return join(entries, "\n")
end

function gen_plugin(p::Gitignore, t::Template, pkg_dir::AbstractString)
    t.git && gen_file(joinpath(pkg_dir, ".gitignore"), render_plugin(p, t))
end

"""
    Tests(; file="$(contractuser(default_file("runtests.jl")))", project=false)

Sets up testing for packages.

## Keyword Arguments
- `file::AbstractString`: Template file for the `runtests.jl`.
- `project::Bool`: Whether or not to create a new project for tests (`test/Project.toml`).
  See [here](https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1) for more details.

!!! note
    Managing test dependencies with `test/Project.toml` is only supported in Julia 1.2 and later.
"""
@with_kw_noshow struct Tests <: BasicPlugin
    file::String = default_file("runtests.jl")
    project::Bool = false
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")
view(::Tests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

function gen_plugin(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal BasicPlugin behaviour to create the test script.
    invoke(gen_plugin, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)

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
