using Documenter: Documenter, makedocs, deploydocs
using PkgTemplates: PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    authors="Chris de Graaf, Invenia Technical Computing Corporation",
    sitename="PkgTemplates.jl",
    format=Documenter.HTML(;
        repolink="https://github.com/JuliaCI/PkgTemplates.jl",
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliaci.github.io/PkgTemplates.jl",
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
    repo="github.com/JuliaCI/PkgTemplates.jl",
)
