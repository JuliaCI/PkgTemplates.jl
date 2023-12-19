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

source(p::Readme) = p.file
destination(p::Readme) = p.destination

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
    subtypes(BadgePlugin)...
]
