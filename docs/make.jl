using Documenter
using PkgTemplates: PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    authors="Chris de Graaf, Invenia Technical Computing Corporation",
    repo="https://github.com/invenia/PkgTemplates.jl/blob/{commit}{path}#L{line}",
    sitename="PkgTemplates.jl",
    format=Documenter.HTML(;
        canonical="https://invenia.github.io/PkgTemplates.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "user.md",
        "Developer Guide" => "developer.md",
    ],
)

deploydocs(;
    repo="github.com/invenia/PkgTemplates.jl",
)
