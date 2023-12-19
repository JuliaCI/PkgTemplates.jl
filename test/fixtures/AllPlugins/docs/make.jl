using AllPlugins
using Documenter

DocMeta.setdocmeta!(AllPlugins, :DocTestSetup, :(using AllPlugins); recursive=true)

makedocs(;
    modules=[AllPlugins],
    authors="tester",
    repo="https://github.com/tester/AllPlugins.jl/blob/{commit}{path}#{line}",
    sitename="AllPlugins.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
