"""
    GitHubPages(; assets::Vector{AbstractString}=String[]) -> GitHubPages

Add GitHubPages to a template's plugins to add Documenter.jl support via GitHub Pages.

# Keyword Arguments
* `assets::Vector{String}=String[]`: Array of paths to Documenter asset files.
"""
@auto_hash_equals struct GitHubPages <: Documenter
    gitignore_files::Vector{AbstractString}
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

"""
    badges(\_::GitHubPages, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::GitHubPages`: plugin whose badges we are generating.
* `user::AbstractString`: GitHub username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::GitHubPages, user::AbstractString, pkg_name::AbstractString)
    return [
        "[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://$user.github.io/$pkg_name.jl/stable)"
        "[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://$user.github.io/$pkg_name.jl/latest)"
    ]
end

"""
    gen_plugin(plugin::GitHubPages, template::Template, pkg_name::AbstractString)

Generate the "docs" directory and set up direct HTML output from Documenter to be pushed
to GitHub Pages.

# Arguments
* `plugin::GitHubPages`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
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

                deploydocs(
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
