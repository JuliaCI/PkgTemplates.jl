using WackyOptions
using Documenter

DocMeta.setdocmeta!(WackyOptions, :DocTestSetup, :(using WackyOptions); recursive=true)

makedocs(;
    modules=[WackyOptions],
    authors="tester",
    sitename="WackyOptions.jl",
    format=Documenter.HTML(;
        canonical="http://example.com",
        edit_link=:commit,
        assets=[
            "assets/static.txt",
        ],
    ),
    pages=[
        "Home" => "index.md",
    ],
    bar="baz",
    foo="bar",
)

deploydocs(;
    repo="x.com/tester/WackyOptions.jl",
    devbranch="foobar",
)
