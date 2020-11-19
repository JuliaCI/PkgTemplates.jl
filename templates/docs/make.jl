using {{{PKG}}}
using Documenter

DocMeta.setdocmeta!({{{PKG}}}, :DocTestSetup, :(using {{{PKG}}}); recursive=true)

makedocs(;
    modules=[{{{PKG}}}],
    authors="{{{AUTHORS}}}",
    repo="https://{{{REPO}}}/blob/{commit}{path}#{line}",
    sitename="{{{PKG}}}.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
{{#CANONICAL}}
        canonical="{{{CANONICAL}}}",
{{/CANONICAL}}
        assets={{^HAS_ASSETS}}String{{/HAS_ASSETS}}[{{^HAS_ASSETS}}],{{/HAS_ASSETS}}
{{#ASSETS}}
            "assets/{{{.}}}",
{{/ASSETS}}
{{#HAS_ASSETS}}
        ],
{{/HAS_ASSETS}}
    ),
    pages=[
        "Home" => "index.md",
    ],
{{#MAKEDOCS_KWARGS}}
    {{{first}}}={{{second}}},
{{/MAKEDOCS_KWARGS}}
)
{{#HAS_DEPLOY}}

deploydocs(;
    repo="{{{REPO}}}",
{{#BRANCH}}
    devbranch="{{{BRANCH}}}",
{{/BRANCH}}
)
{{/HAS_DEPLOY}}
