using {{PKG}}
using Documenter

makedocs(
    modules=[{{PKG}}],
    authors="{{AUTHORS}}",
    repo="{{REPO}}",
    sitename="{{PKG}}.jl",
    format=Documenter.HTML(;
        canonical="{{CANONICAL}}",
        assets={{^HAS_ASSETS}}String{{/HAS_ASSETS}}[{{^HAS_ASSETS}}],{{/HAS_ASSETS}}
            {{#ASSETS}}
            "{{.}}",
            {{/ASSETS}}
{{#HAS_ASSETS}}
        ],
{{/HAS_ASSETS}}
    ),
    pages=[
        "Home" => "index.md",
    ],
    {{#MAKEDOCS_KWARGS}}
    {{first}}={{second}},
    {{/MAKEDOCS_KWARGS}}
)
{{#HAS_DEPLOY}}

deploydocs(;
    repo="{{REPO}}",
)
{{/HAS_DEPLOY}}
