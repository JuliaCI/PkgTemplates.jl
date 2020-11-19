using DocumenterGitHubActions
using Documenter

DocMeta.setdocmeta!(DocumenterGitHubActions, :DocTestSetup, :(using DocumenterGitHubActions); recursive=true)

makedocs(;
    modules=[DocumenterGitHubActions],
    authors="tester",
    repo="https://github.com/tester/DocumenterGitHubActions.jl/blob/{commit}{path}#{line}",
    sitename="DocumenterGitHubActions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tester.github.io/DocumenterGitHubActions.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tester/DocumenterGitHubActions.jl",
)
