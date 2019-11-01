using {{{PKG}}}
using Documenter

makedocs(;
    modules=[{{{PKG}}}],
    authors="{{{AUTHORS}}}",
    repo="https://{{{REPO}}}/blob/{commit}{path}#L{line}",
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
)
{{/HAS_DEPLOY}}
