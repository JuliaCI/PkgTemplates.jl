using Documenter, PkgTemplates

makedocs(
    modules=[PkgTemplates],
    format=:html,
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/christopher-dG/PkgTemplates.jl/blob/{commit}{path}#L{line}",
    sitename="PkgTemplates.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
    ],
)

deploydocs(
    repo="github.com/christopher-dG/PkgTemplates.jl.git",
    target="build",
    julia="0.6",
    deps=nothing,
    make=nothing,
)
