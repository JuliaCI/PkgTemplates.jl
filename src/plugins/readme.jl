"""
    Readme(;
        file="$(contractuser(default_file("README.md")))",
        destination="README.md",
        inline_badges=false,
    )

Creates a `README` file that contains badges for other included plugins.

## Keyword Arguments
- `file::AbstractString`: Template file for the `README`.
- `destination::AbstractString`: File destination, relative to the repository root.
  For example, values of `"README"` or `"README.rst"` might be desired.
- `inline_badges::Bool`: Whether or not to put the badges on the same line as the package name.
- `badge_order::Vector{typeof(Plugin)}`: Plugins in the order their badges should appear.
- `badge_off::Vector{typeof(Plugin)}`: Plugins which should not have their badges added.
"""
@plugin struct Readme <: FilePlugin
    file::String = default_file("README.md")
    destination::String = "README.md"
    inline_badges::Bool = false
    badge_order::Vector{typeof(Plugin)} = default_badge_order()
    badge_off::Vector{typeof(Plugin)} = []
end


isfixable(p::Readme, pkg_dir) = true
source(p::Readme) = p.file
destination(p::Readme) = p.destination

"""
    hook(p::Readme, t::Template, pkg_dir::AbstractString)

Overloads the `hook` function for the `Readme` file plugin. In case `fixup` is used and there is an existing README, a new README is proposed that complies with the template, but it the existing one is not overwritten.
"""
function hook(p::Readme, t::Template, pkg_dir::AbstractString)
    source(p) === nothing && return
    pkg = pkg_name(pkg_dir)
    path = joinpath(pkg_dir, destination(p))
    text = render_plugin(p, t, pkg)
    if isfile(path)
        path_fixed = replace(path, ".md" => "_fixed.md")
        @warn "README file already exists at $path. Generating a fixed but empty version from template at $path_fixed. You will most likely just have to copy and paste the content from the existing README into the fixed version and then overwrite $path with $path_fixed."
        gen_file(path_fixed, text)
    else
        gen_file(path, text)
    end
end

function view(p::Readme, t::Template, pkg::AbstractString)
    # Explicitly ordered badges go first.
    strings = String[]
    done = DataType[]
    foreach(p.badge_order) do T
        if hasplugin(t, T) && !in(T, p.badge_off)
            append!(strings, badges(getplugin(t, T), t, pkg))
            push!(done, T)
        end
    end
    # And the rest go after, in no particular order.
    foreach(setdiff(map(typeof, t.plugins), done)) do T
        if !in(T, p.badge_off)
            append!(strings, badges(getplugin(t, T), t, pkg))
        end
    end

    return Dict(
        "BADGES" => strings,
        "HAS_CITATION" => hasplugin(t, Citation) && getplugin(t, Citation).readme,
        "HAS_INLINE_BADGES" => !isempty(strings) && p.inline_badges,
        "PKG" => pkg,
    )
end

default_badge_order() = [
    Documenter{GitHubActions},
    Documenter{GitLabCI},
    Documenter{TravisCI},
    GitHubActions,
    GitLabCI,
    TravisCI,
    AppVeyor,
    DroneCI,
    CirrusCI,
    Codecov,
    Coveralls,
    subtypes(BadgePlugin)...,
]
