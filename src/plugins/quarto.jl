"""
    Quarto(;
        index_qmd::String = default_file("quarto", "index.qmd")
        readme_qmd::String = default_file("quarto", "README.qmd")
        config::String = default_file("quarto", "_quarto.yml")
    )
"""
@plugin struct Quarto <: Plugin
    index_qmd::String = default_file("quarto", "index.qmd")
    readme_qmd::String = default_file("quarto", "README.qmd")
    make_jl::String = default_file("quarto", "make.jl")
    config::String = default_file("quarto", "_quarto.yml")
end

function isfixable(::Quarto, pkg_dir)
    return true
end

PkgTemplates.view(p::Quarto, t::Template, pkg::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "PKG" => pkg,
    "REPO" => "$(t.host)/$(t.user)/$pkg.jl",
    "USER" => t.user,
)

function PkgTemplates.validate(p::Quarto, t::Template)
    if PkgTemplates.hasplugin(t, Documenter)
        # Overwrite make.jl file path (dirty solution)
        doc_plugin = t.plugins[findall(typeof.(t.plugins) .<: Documenter)][1]
        @assert doc_plugin.make_jl == p.make_jl "make.jl file path mismatch between Quarto and Documenter plugin. When using the Quarto plugin, make sure that the Documenter plugin points to $(p.make_jl)"
    end
end

function PkgTemplates.hook(p::Quarto, t::Template, pkg_dir::AbstractString)

    pkg = pkg_name(pkg_dir)
    docs_dir = joinpath(pkg_dir, "docs")
    assets_dir = joinpath(docs_dir, "src", "assets")
    ispath(assets_dir) || mkpath(assets_dir)

    # Readme file:
    if PkgTemplates.hasplugin(t, Readme)
        p_readme = t.plugins[findall(typeof.(t.plugins) .<: Readme)][1]
        v = merge(combined_view(p, t, pkg), combined_view(p_readme, t, pkg))        # merge views from both plugins
    else
        v = combined_view(p, t, pkg)
    end
    readme = render_file(p.readme_qmd, v, tags(p))
    gen_file(joinpath(pkg_dir, "README.qmd"), readme)

    # Index file:
    index = render_file(p.index_qmd, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "src", "index.qmd"), index)

    # Make.jl:
    makejl = render_file(p.make_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "make.jl"), makejl)
    run(`chmod u+x $(joinpath(docs_dir, "make.jl"))`)       # turn into executable

    # Config file:
    config = render_file(p.config, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(pkg_dir, "_quarto.yml"), config)
end