using DocumenterTravis
using Documenter

DocMeta.setdocmeta!(DocumenterTravis, :DocTestSetup, :(using DocumenterTravis); recursive=true)

makedocs(;
    modules=[DocumenterTravis],
    authors="tester",
    sitename="DocumenterTravis.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tester.github.io/DocumenterTravis.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tester/DocumenterTravis.jl",
    devbranch="main",
)
