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
                throw(ArgumentError("Asset file $file does not exist"))
            end
        end
        # Windows Git recognizes these paths as well.
        new(["/docs/build/", "/docs/site/"], assets)
    end
end

"""
    badges(\_::GitHubPages, pkg_name::AbstractString, t::Template) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::GitHubPages`: plugin whose badges we are generating.
* `t::Template`: Template configuration options.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::GitHubPages, t::Template, pkg_name::AbstractString)
    if haskey(t.plugins, TravisCI)
        user = strip(URI(t.remote_prefix).path, '/')
        return [
            "[![stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://$user.github.io/$pkg_name.jl/stable)"
            "[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://$user.github.io/$pkg_name.jl/latest)"
        ]
    end
    return String[]
end


"""
    gen_plugin(plugin::GitHubPages, template::Template, pkg_name::AbstractString)

Generate the "docs" folder and set up direct HTML output from Documenter to be pushed to
GitHub Pages.

# Arguments
* `plugin::GitHubPages`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated directories.
"""
function gen_plugin(plugin::GitHubPages, template::Template, pkg_name::AbstractString)
    invoke(
        gen_plugin, Tuple{Documenter, Template, AbstractString},
        plugin, template, pkg_name
    )
    if haskey(template.plugins, TravisCI)
        docs_src = joinpath(template.path, pkg_name, "docs", "src")
        user = strip(URI(template.remote_prefix).path, '/')
        open(joinpath(dirname(docs_src), "make.jl"), "a") do file
            write(
                file,
                """

                deploydocs(
                    repo="github.com/$user/$pkg_name.jl",
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
