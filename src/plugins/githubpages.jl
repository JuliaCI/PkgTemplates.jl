"""
    GitHubPages(; assets::Vector{<:AbstractString}=String[]) -> GitHubPages

Add `GitHubPages` to a template's plugins to add [`Documenter`](@ref) support via GitHub
Pages, including automatic uploading of documentation from [`TravisCI`](@ref). Also
adds appropriate badges to the README, and updates the `.gitignore` accordingly.

# Keyword Arguments
* `assets::Vector{<:AbstractString}=String[]`: Array of paths to Documenter asset files.

!!! note
    If deploying documentation with Travis CI, don't forget to complete the required
    configuration (see
    [here](https://juliadocs.github.io/Documenter.jl/stable/man/hosting/#SSH-Deploy-Keys-1)).
"""
struct GitHubPages <: Documenter
    gitignore::Vector{String}
    assets::Vector{String}

    function GitHubPages(; assets::Vector{<:AbstractString}=String[])
        for file in assets
            if !isfile(file)
                throw(ArgumentError("Asset file $(abspath(file)) does not exist"))
            end
        end
        # Windows Git recognizes these paths as well.
        new(["/docs/build/", "/docs/site/"], abspath.(assets))
    end
end

function badges(::GitHubPages, user::AbstractString, pkg_name::AbstractString)
    return [
        format(Badge(
            "Stable",
            "https://img.shields.io/badge/docs-stable-blue.svg",
            "https://$user.github.io/$pkg_name.jl/stable"
        )),
        format(Badge(
            "Dev",
            "https://img.shields.io/badge/docs-dev-blue.svg",
            "https://$user.github.io/$pkg_name.jl/dev"
        )),
    ]
end

function gen_plugin(p::GitHubPages, t::Template, pkg_name::AbstractString)
    invoke(gen_plugin, Tuple{Documenter, Template, AbstractString}, p, t, pkg_name)

    if haskey(t.plugins, TravisCI)
        docs_src = joinpath(t.dir, pkg_name, "docs", "src")
        open(joinpath(dirname(docs_src), "make.jl"), "a") do file
            write(
                file,
                """

                deploydocs(;
                    repo="$(t.host)/$(t.user)/$pkg_name.jl",
                )
                """
            )
        end
    end
    return ["docs/"]
end

function interactive(::Type{GitHubPages})
    print("GitHubPages: Enter any Documenter asset files (separated by spaces) []: ")
    return GitHubPages(; assets=string.(split(readline())))
end
