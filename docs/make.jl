using Documenter, PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    format=:html,
    pages=[
        "Home" => "index.md",
        "Package Generation" => "pages/package_generation.md",
        "Plugins" => "pages/plugins.md",
        "Plugin Development" => "pages/plugin_development.md",
        "Licenses" => "pages/licenses.md",
        "Index" => "pages/index.md",
    ],
    repo="https://github.com/christopher-dG/PkgTemplates.jl/blob/{commit}{path}#L{line}",
    sitename="PkgTemplates.jl",
    authors="Chris de Graaf, Invenia Technical Computing Corporation",
    assets=[],
)

deploydocs(;
    repo="github.com/christopher-dG/PkgTemplates.jl",
    target="build",
    julia="0.6",
    deps=nothing,
    make=nothing,
)
