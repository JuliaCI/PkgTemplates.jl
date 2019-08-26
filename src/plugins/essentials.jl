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

@with_kw struct Readme <: BasicPlugin
    file::String = default_file("README.md")
    destination::String = "README.md"
    inline_badges::Bool = false
end

source(p::Readme) = p.file
destination(p::Readme) = p.destination

function view(::Readme, t::Template, pkg::AbstractString)
    # Explicitly ordered badges go first.
    strings = String[]
    done = DataType[]
    foreach(BADGE_ORDER) do T
        if hasplugin(t, T)
            bs = badges(t.plugins[T], t, pkg)
            append!(strings, badges(t.plugins[T], t, pkg))
            push!(done, T)
        end
    end
    foreach(setdiff(keys(t.plugins), done)) do T
        bs = badges(t.plugins[T], t, pkg)
        text *= "\n" * join(badges(t.plugins[T], t.user, pkg), "\n")
    end

    return Dict(
        "HAS_CITATION" => hasplugin(t, Citation),
        "HAS_INLINE_BADGES" => p.inline_badges,
    )
end

struct License <: Plugin
    path::String
    destination::String

    function License(name::AbstractString="MIT", destination::AbstractString="LICENSE")
        return new(license_path(name), destination)
    end
end

function license_path(license::AbstractString)
    path = joinpath(LICENSE_DIR, license)
    isfile(path) || throw(ArgumentError("License '$license' is not available"))
    return path
end

read_license(license::AbstractString) = string(readchomp(license_path(license)))

function render_plugin(p::License, t::Template)
    text = "Copyright (c) $(year(today())) $(t.authors)\n"
    license = read(p.path, String)
    startswith(license, "\n") || (text *= "\n")
    return text * license
end

function gen_plugin(p::License, t::Template, pkg_dir::AbstractString)
    gen_file(joinpath(pkg_dir, p.destination), render_plugin(p, t))
end

struct Gitignore <: Plugin end

function render_plugin(p::Gitignore, t::Template)
    entries = mapreduce(gitignore, append!, values(t.plugins); init=[".DS_Store", "/dev/"])
    # Only ignore manifests at the repo root.
    t.manifest || "Manifest.toml" in entries || push!(entries, "/Manifest.toml")
    unique!(sort!(entries))
    return join(entries, "\n")
end

function gen_plugin(p::Gitignore, t::Template, pkg_dir::AbstractString)
    gen_file(joinpath(pkg_dir, ".gitignore"), render_plugin(p, t))
end

@with_kw struct Tests <: BasicPlugin
    file::String = default_file("runtests.jl")
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")
view(::Tests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

function gen_plugin(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal BasicPlugin behaviour to create the test script.
    invoke(gen_plugin, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)

    # Add the Test dependency as a test-only dependency.
    # To avoid visual noise from adding/removing the dependency, insert it manually.
    proj = current_project()
    try
        Pkg.activate(pkg_dir)
        lines = readlines(joinpath(pkg_dir, "Project.toml"))
        dep = "Test = $(repr(TEST_UUID))"
        push!(lines, "[extras]", dep, "", "[targets]", "test = [\"Test\"]")
        gen_file(joinpath(pkg_dir, "Project.toml"), join(lines, "\n"))
        touch(joinpath(pkg_dir, "Manifest.toml"))  # File must exist to be modified by Pkg.
        Pkg.update()  # Clean up both Manifest.toml and Project.toml.
    finally
        proj === nothing ? Pkg.activate() : Pkg.activate(proj)
    end
end
