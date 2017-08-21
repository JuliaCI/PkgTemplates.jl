"""
    GitHubPages(; assets::Vector{AbstractString}=String[]) -> GitHubPages

Add `GitHubPages` to a template's plugins to add [Documenter](@ref) support via GitHub
Pages, including automatic uploading of documentation from [`TravisCI`](@ref). Also
adds appropriate badges to the README, and updates the `.gitignore` accordingly.

# Keyword Arguments
* `assets::Vector{String}=String[]`: Array of paths to Documenter asset files.
"""
@auto_hash_equals struct GitHubPages <: Documenter
    gitignore::Vector{AbstractString}
    assets::Vector{AbstractString}

    function GitHubPages(; assets::Vector{String}=String[])
        for file in assets
            if !isfile(file)
                throw(ArgumentError("Asset file $(abspath(file)) does not exist"))
            end
        end
        # Windows Git recognizes these paths as well.
        new(["/docs/build/", "/docs/site/"], assets)
    end
end

function badges(_::GitHubPages, user::AbstractString, pkg_name::AbstractString)
    return [
        format(Badge(
            "Stable",
            "https://img.shields.io/badge/docs-stable-blue.svg",
            "https://$user.github.io/$pkg_name.jl/stable"
        )),
        format(Badge(
            "Latest",
            "https://img.shields.io/badge/docs-latest-blue.svg",
            "https://$user.github.io/$pkg_name.jl/latest"
        )),
    ]
end

function gen_plugin(plugin::GitHubPages, template::Template, pkg_name::AbstractString)
    invoke(
        gen_plugin, Tuple{Documenter, Template, AbstractString},
        plugin, template, pkg_name
    )
    if haskey(template.plugins, TravisCI)
        docs_src = joinpath(template.temp_dir, pkg_name, "docs", "src")
        open(joinpath(dirname(docs_src), "make.jl"), "a") do file
            write(
                file,
                """

                deploydocs(;
                    repo="github.com/$(template.user)/$pkg_name.jl",
                    target="build",
                    julia="0.6",
                    deps=nothing,
                    make=nothing,
                )
                """
            )
        end
    end
    return ["docs/"]
end

function interactive(plugin_type::Type{GitHubPages})
    print("Enter any Documenter assets files for GitHubPages (separated by spaces) []")
    return GitHubPages(; assets=String.(split(readline())))
end
