const PACKAGECOMPILER_DEP = PackageSpec(;
    name="PackageCompiler",
    uuid="9b87118b-4619-50d2-8e1e-99f35a4d4d9d",
)

"""
    PackageCompiler(;
        make_jl       = "$(contractuser(default_file("build", "make.jl")))",
        precompile_jl = "$(contractuser(default_file("build", "precompile.jl")))",
        sysimage_name = "sysimage",
        packages      = :deps
    )

Sets up sysimage generation via [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl).

When in the top-level directory of the generated package, a system image should be created by running:
```
shell\$ julia build/make.jl
```

## Keyword Arguments
- `make_jl::AbstractString`: Template file for `make.jl`.
- `precompile_jl::AbstractString`: Template file for `precompile.jl`.
- `sysimage_name::AbstractString`: Base path to the generated sysimage; an
  appropriate extension will be added depending on the OS.
- `packages`: Determines the list of packages to bake into the
  sysimage (see below).

## List of packages to include in the sysimage

The `packages` keyword argument allows specifying which packages should be
included in the sysimage. Supported values are:

- `:deps`: include in the sysimage all direct dependencies of the package.
- `:pkg`: include in the sysimage the package itself.
- vector of package names, as strings or symbols: include all listed packages into the sysimage.

## Examples
```
# Explicitly list packages to include into the sysimage
PackageCompiler(packages = [:Plots,  :DataFrames])
PackageCompiler(packages = ["Plots", "DataFrames"])

# Build a sysimage containing all direct dependencies of the current package
# (this is the default)
PackageCompiler(packages = :deps)

# Build a sysimage containing the current package itself
PackageCompiler(packages = :pkg)

# Generated sysimage will be located at \$(PWD)/foo/bar/image.\$(EXT)
PackageCompiler(sysimage_name = joinpath("foo", "bar", "image"))
```
"""
@plugin struct PackageCompiler <: Plugin
    make_jl::String = default_file("build", "make.jl")
    precompile_jl::String = default_file("build", "precompile.jl")
    sysimage_name::String = "sysimage"
    packages::Union{Symbol, AbstractVector} = :deps
end

priority(::PackageCompiler, ::Function) = DEFAULT_PRIORITY - 1  # We need SrcDir to go first.

function view(p::PackageCompiler, t::Template, pkg::AbstractString)
    d = Dict{String, Any}(
        "PKG" => pkg,
        "SYSIMAGE_NAME" => p.sysimage_name,
    )

    if p.packages == :deps
        d["SYSIMAGE_DEPS"] = true
    elseif p.packages == :pkg
        d["SYSIMAGE_LIST"] = pkg
    else
        d["SYSIMAGE_LIST"] = p.packages
    end

    d
end

function hook(p::PackageCompiler, t::Template, pkg_dir::AbstractString)
    pkg = basename(pkg_dir)
    build_dir = joinpath(pkg_dir, "build")

    # Generate files.
    make = render_file(p.make_jl, combined_view(p, t, pkg), tags(p))
    precompile = render_file(p.precompile_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "make.jl"), make)
    gen_file(joinpath(build_dir, "precompile.jl"), precompile)

    # Create the compilation project.
    with_project(build_dir) do
        Pkg.add(PACKAGECOMPILER_DEP)
        cd(() -> Pkg.develop(PackageSpec(; path="..")), build_dir)
    end
end
