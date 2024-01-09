using DocumenterGitHubActions
using Documenter

DocMeta.setdocmeta!(DocumenterGitHubActions, :DocTestSetup, :(using DocumenterGitHubActions); recursive=true)

makedocs(;
    modules=[DocumenterGitHubActions],
    authors="tester",
    sitename="DocumenterGitHubActions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tester.github.io/DocumenterGitHubActions.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tester/DocumenterGitHubActions.jl",
    devbranch="main",
)
