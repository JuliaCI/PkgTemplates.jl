using DocumenterGitLabCI
using Documenter

DocMeta.setdocmeta!(DocumenterGitLabCI, :DocTestSetup, :(using DocumenterGitLabCI); recursive=true)

makedocs(;
    modules=[DocumenterGitLabCI],
    authors="tester",
    sitename="DocumenterGitLabCI.jl",
    format=Documenter.HTML(;
        canonical="https://tester.gitlab.io/DocumenterGitLabCI.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
