using Documenter: Documenter, makedocs, deploydocs
using PkgTemplates: PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    authors="Chris de Graaf, Invenia Technical Computing Corporation",
    repo="https://github.com/invenia/PkgTemplates.jl/blob/{commit}{path}#{line}",
    sitename="PkgTemplates.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://invenia.github.io/PkgTemplates.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "User Guide" => "user.md",
        "Developer Guide" => "developer.md",
        "Migrating To PkgTemplates 0.7+" => "migrating.md",
    ],
)

deploydocs(;
    repo="github.com/invenia/PkgTemplates.jl",
)
