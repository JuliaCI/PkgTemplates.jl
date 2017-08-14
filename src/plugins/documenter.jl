"""
Add a Documenter subtype to a template's plugins to add support for
[Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
"""
abstract type Documenter <: Plugin end

"""
    gen_plugin(plugin::Documenter, template::Template, pkg_name::AbstractString) -> Void

Generate the "docs" directory with files common to all Documenter subtypes.

# Arguments
* `plugin::Documenter`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.
"""
function gen_plugin(plugin::Documenter, template::Template, pkg_name::AbstractString)
    info("Adding Documenter.jl")
    Pkg.add("Documenter")
    path = joinpath(template.path, pkg_name)
    docs_dir = joinpath(path, "docs", "src")
    mkpath(docs_dir)
    if !isempty(plugin.assets)
        mkpath(joinpath(docs_dir, "assets"))
        for file in plugin.assets
            cp(file, joinpath(docs_dir, "assets", basename(file)))
        end
        # We want something that looks like the following:
        # [
        #         assets/file1,
        #         assets/file2,
        #     ]
        const TAB = repeat(" ", 4)
        assets = "[\n"
        for file in plugin.assets
            assets *= """$(TAB^2)"assets/$(basename(file))",\n"""
        end
        assets *= "$TAB]"

    else
        assets = "[]"
    end
    user = strip(URI(template.remote_prefix).path, '/')
    text = """
        using Documenter, $pkg_name

        makedocs(
            modules=[$pkg_name],
            format=:html,
            pages=[
                "Home" => "index.md",
            ],
            repo="$(template.remote_prefix)$pkg_name.jl/blob/{commit}{path}#L{line}",
            sitename="$pkg_name.jl",
            authors="$(template.authors)",
            assets=$assets,
        )
        """

    gen_file(joinpath(dirname(docs_dir), "make.jl"), text)
    open(joinpath(docs_dir,  "index.md"), "w") do fp
        write(fp, "# $pkg_name")
    end
    readme_path = ""
    try
        readme_path = joinpath(template.path, pkg_name, "README.md")
    catch
    end
    if isfile(readme_path)
        cp(readme_path, joinpath(docs_dir, "index.md"), remove_destination=true)
    end
end
