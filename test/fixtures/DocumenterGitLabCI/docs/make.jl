using DocumenterGitLabCI
using Documenter

DocMeta.setdocmeta!(DocumenterGitLabCI, :DocTestSetup, :(using DocumenterGitLabCI); recursive=true)

makedocs(;
    modules=[DocumenterGitLabCI],
    authors="tester",
    repo="https://github.com/tester/DocumenterGitLabCI.jl/blob/{commit}{path}#{line}",
    sitename="DocumenterGitLabCI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tester.gitlab.io/DocumenterGitLabCI.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
