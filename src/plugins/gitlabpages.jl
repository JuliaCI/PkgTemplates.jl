"""
    GitLabPages(; assets::Vector{<:AbstractString}=String[]) -> GitLabPages

Add `GitLabPages` to a template's plugins to add [`Documenter`](@ref) support via GitLab
Pages, including automatic uploading of documentation from [`GitLabCI`](@ref). Also
adds appropriate badges to the README, and updates the `.gitignore` accordingly.

# Keyword Arguments
* `assets::Vector{<:AbstractString}=String[]`: Array of paths to Documenter asset files.
"""
struct GitLabPages <: Documenter
    gitignore::Vector{String}
    assets::Vector{String}

    function GitLabPages(; assets::Vector{<:AbstractString}=String[])
        for file in assets
            if !isfile(file)
                throw(ArgumentError("Asset file $(abspath(file)) does not exist"))
            end
        end
        # Windows Git recognizes these paths as well.
        new(["/docs/build/", "/docs/site/"], abspath.(assets))
    end
end

function badges(::GitLabPages, user::AbstractString, pkg_name::AbstractString)
    return [
        #=
        format(Badge(
            "Stable",
            "https://img.shields.io/badge/docs-stable-blue.svg",
            "https://$user.gitlab.io/$pkg_name.jl/stable"
        )),
        =#
        format(Badge(
            "Dev",
            "https://img.shields.io/badge/docs-dev-blue.svg",
            "https://$user.gitlab.io/$pkg_name.jl/dev"
        )),
    ]
end

function gen_plugin(p::GitLabPages, t::Template, pkg_name::AbstractString)
    invoke(gen_plugin, Tuple{Documenter, Template, AbstractString}, p, t, pkg_name)
    return ["docs/"]
end

function interactive(::Type{GitLabPages})
    print("GitLabPages: Enter any Documenter asset files (separated by spaces) []: ")
    return GitLabPages(; assets=string.(split(readline())))
end
