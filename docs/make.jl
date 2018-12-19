using Documenter, PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Package Generation" => "pages/package_generation.md",
        "Plugins" => "pages/plugins.md",
        "Plugin Development" => "pages/plugin_development.md",
        "Licenses" => "pages/licenses.md",
        "Index" => "pages/index.md",
    ],
    repo="https://github.com/invenia/PkgTemplates.jl/blob/{commit}{path}#L{line}",
    sitename="PkgTemplates.jl",
    authors="Chris de Graaf, Invenia Technical Computing Corporation",
    assets=[],
)

deploydocs(;
    repo="github.com/invenia/PkgTemplates.jl",
)
