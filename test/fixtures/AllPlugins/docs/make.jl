using AllPlugins
using Documenter

makedocs(;
    modules=[AllPlugins],
    authors="tester",
    repo="https://github.com/tester/AllPlugins.jl/blob/{commit}{path}#L{line}",
    sitename="AllPlugins.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
