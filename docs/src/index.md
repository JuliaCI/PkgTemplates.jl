# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/PkgTemplates.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/PkgTemplates.jl/latest)
[![Build Status](https://travis-ci.org/invenia/PkgTemplates.jl.svg?branch=master)](https://travis-ci.org/invenia/PkgTemplates.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/invenia/PkgTemplates.jl?svg=true)](https://ci.appveyor.com/project/invenia/PkgTemplates-jl)
[![CodeCov](https://codecov.io/gh/invenia/PkgTemplates.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PkgTemplates.jl)

**PkgTemplates is a Julia package for creating new Julia packages in an easy,
repeatable, and customizable way.**

## Installation

`PkgTemplates` is registered in
[`METADATA.jl`](https://github.com/JuliaLang/METADATA.jl), so run
`Pkg.add("PkgTemplates")` for the latest release, or
`Pkg.clone("PkgTemplates")` for the development version.

## Usage

The simplest template only requires your GitHub username.

```@repl
using PkgTemplates
t = Template(; user="invenia")
generate("MyPkg", t)
cd(joinpath(t.dir, "MyPkg")); run(`git ls-tree -r --name-only HEAD`)
```

However, we can also configure a number of keyword arguments to [`Template`](@ref) and
[`generate`](@ref):

```@repl
using PkgTemplates
t = Template(;
    user="invenia",
    license="MIT",
    authors=["Chris de Graaf", "Invenia Technical Computing Corporation"],
    years="2016-2017",
    dir=joinpath(ENV["HOME"], "code"),
    julia_version=v"0.5.2",
    requirements=["PkgTemplates"],
    git_config=Dict("diff.renames" => true),
    plugins=[
        TravisCI(),
        CodeCov(; config_file=nothing),
        Coveralls(),
        AppVeyor(),
        GitHubPages(; assets=[joinpath(ENV["HOME"], "invenia.css")]),
    ],
)
generate("MyPkg", t; force=true, ssh=true)
cd(joinpath(t.dir, "MyPkg")); run(`git ls-tree -r --name-only HEAD`)
```

## Comparison to [PkgDev](https://github.com/JuliaLang/PkgDev.jl)

`PkgTemplates` is similar in functionality to `PkgDev`'s `generate` function.
However, `PkgTemplates` offers more customizability in templates and more
extensibility via plugins. For the package registration and release management
features that `PkgTemplates` lacks, you are encouraged to use
[AttoBot](https://github.com/apps/attobot) instead.
