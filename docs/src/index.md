# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/PkgTemplates.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/PkgTemplates.jl/latest)
[![Build Status](https://travis-ci.org/invenia/PkgTemplates.jl.svg?branch=master)](https://travis-ci.org/invenia/PkgTemplates.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/r24xamruqlm88uti/branch/master?svg=true)](https://ci.appveyor.com/project/christopher-dG/pkgtemplates-jl/branch/master)
[![Codecov](https://codecov.io/gh/invenia/PkgTemplates.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PkgTemplates.jl)

**PkgTemplates is a Julia package for creating new Julia packages in an easy,
repeatable, and customizable way.**

## Installation

```julia
pkg> add PkgTemplates
```

## Usage

```@setup usage
run(`git config --global user.name "Travis"`)
run(`git config --global user.email "travis@c.i"`)
run(`git config --global github.user "travis"`)
using Pkg
Pkg.activate(mktempdir())
```

The simplest template requires no arguments.


```@repl usage
using PkgTemplates
t = Template()
generate("MyPkg", t)
run(`git -C $(joinpath(t.dir, "MyPkg")) ls-files`);
```

However, we can also configure a number of keyword arguments to
[`Template`](@ref):

```@repl usage
using PkgTemplates
t = Template(;
    user="myusername",
    license="MIT",
    authors=["Chris de Graaf", "Invenia Technical Computing Corporation"],
    dir="~/code",
    julia_version=v"0.7",
    ssh=true,
    plugins=[
        TravisCI(),
        Codecov(),
        Coveralls(),
        AppVeyor(),
        GitHubPages(),
    ],
)
generate("MyPkg2", t)
run(`git -C $(joinpath(t.dir, "MyPkg2")) ls-files`);
```

If that looks like a lot of work, you can also create templates interactively
with [`interactive_template`](@ref):

[![asciicast](https://asciinema.org/a/31bZqW9u8h5RHpd7gtsemioRV.png)](https://asciinema.org/a/31bZqW9u8h5RHpd7gtsemioRV)

And if that's **still** too much work for you, you can call
`interactive_template` with `fast=true` to use default values for everything
but username and plugin selection.

You can also use [`generate_interactive`](@ref) to interactively generate a template and then
immediately use it to create a new package.

## Comparison to PkgDev

`PkgTemplates` is similar in functionality to
[`PkgDev`](https://github.com/JuliaLang/PkgDev.jl)'s `generate` function. However,
`PkgTemplates` offers more customizability in templates and more extensibility via plugins.
For the package registration and release management features that `PkgTemplates` doesn't
include, you are encouraged to use [AttoBot](https://github.com/apps/attobot) instead.

## Contributing

It's extremely easy to extend `PkgTemplates` with new plugins. To get started,
check out the
[plugin development guide](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugin_development.html).
