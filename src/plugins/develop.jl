"""
    Develop()

Adds generated packages to the current environment by `dev`ing them.
See the Pkg documentation
[here](https://julialang.github.io/Pkg.jl/v1/managing-packages/#Developing-packages-1)
for more details.
"""
struct Develop <: Plugin end

function posthook(::Develop, ::Template, pkg_dir::AbstractString)
    Pkg.develop(PackageSpec(; path=pkg_dir))
end
