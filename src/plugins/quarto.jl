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

function PkgTemplates.view(p::Quarto, t::Template, pkg::AbstractString)

    v = Dict{AbstractString,Any}()

    # Inherit view from Readme plugin:
    if PkgTemplates.hasplugin(t, Readme)
        p_readme = t.plugins[findall(typeof.(t.plugins) .<: Readme)][1]
        v = merge(v, combined_view(p_readme, t, pkg))
    end

    # Inherit view from Documenter plugin:
    if PkgTemplates.hasplugin(t, Documenter)
        p_doc = t.plugins[findall(typeof.(t.plugins) .<: Documenter)][1]
        v = merge(v, combined_view(p_doc, t, pkg))
    end

    return v
end

function PkgTemplates.validate(p::Quarto, t::Template)
    if PkgTemplates.hasplugin(t, Documenter)
        # Overwrite make.jl file path (dirty solution)
        doc_plugin = t.plugins[findall(typeof.(t.plugins) .<: Documenter)][1]
        @assert doc_plugin.make_jl == p.make_jl "make.jl file path mismatch between Quarto and Documenter plugin. When using the Quarto plugin, make sure that the Documenter plugin points to $(p.make_jl), i.e. use `Documenter(make_jl=Quarto().make_jl)`"
    end
end

function PkgTemplates.hook(p::Quarto, t::Template, pkg_dir::AbstractString)

    pkg = pkg_name(pkg_dir)
    docs_dir = joinpath(pkg_dir, "docs")
    assets_dir = joinpath(docs_dir, "src", "assets")
    ispath(assets_dir) || mkpath(assets_dir)

    # Readme file:
    readme = render_file(p.readme_qmd, combined_view(p, t, pkg), tags(p))
    path = joinpath(pkg_dir, "README.qmd")
    mkd_path = replace(path, ".qmd" => ".md")
    if isfile(path)
        path_fixed = replace(path, ".qmd" => "_fixed.qmd")
        @warn "README file already exists at $path. Generating a fixed but empty version from template at $path_fixed. You will most likely just have to copy and paste the content from the existing README into the fixed version and then overwrite $path with $path_fixed."
        gen_file(path_fixed, readme)
    elseif isfile(mkd_path)
        backup_path = replace(mkd_path, ".md" => "_backup.md") 
        run(`cp $mkd_path $backup_path`)
        @warn "Existing `README.md` (markdown) file found and backed up as $backup_path. You may have to copy existing contents into the newly generated Quarto file at $path."
        gen_file(path, readme)
    else
        gen_file(path, readme)
    end
    @info "Rendering README"
    run(`quarto render $path`)

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
