using DocumenterTravis
using Documenter

makedocs(;
    modules=[DocumenterTravis],
    authors="tester",
    repo="https://github.com/tester/DocumenterTravis.jl/blob/{commit}{path}#L{line}",
    sitename="DocumenterTravis.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tester.github.io/DocumenterTravis.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tester/DocumenterTravis.jl",
)
