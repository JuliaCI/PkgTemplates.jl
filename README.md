# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaci.github.io/PkgTemplates.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaci.github.io/PkgTemplates.jl/dev)
[![CI](https://github.com/JuliaCI/PkgTemplates.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaCI/PkgTemplates.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Codecov](https://codecov.io/gh/JuliaCI/PkgTemplates.jl/branch/master/graph/badge.svg?token=WsGRSymBmZ)](https://codecov.io/gh/JuliaCI/PkgTemplates.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

**PkgTemplates creates new Julia packages in an easy, repeatable, and customizable way.**

## Installation

Install with the Julia package manager [Pkg](https://pkgdocs.julialang.org/), just like any other registered Julia package:

```jl
pkg> add PkgTemplates  # Press ']' to enter the Pkg REPL mode.
```
or
```jl
julia> using Pkg; Pkg.add("PkgTemplates")
```

## Usage

### Interactive Generation

You can fully customize your package interactively with:

```jl
using PkgTemplates
Template(interactive=true)("MyPkg")
```

### Manual creation

Creating a `Template` is as simple as:

```jl
using PkgTemplates
tpl = Template()
```

The no-keywords constructor assumes the existence of some preexisting Git configuration (show configuration using `git config --list` and set with `git config --global`):

- `user.name`: Your real name, e.g. John Smith.
- `user.email`: Your email address, eg. john.smith@acme.corp.
- `github.user`: Your GitHub username: e.g. john-smith.

Once you have a `Template`, use it to generate a package:

```jl
tpl("MyPkg")
```

However, it's probably desirable to customize the template to your liking with various options and plugins:

```jl
using PkgTemplates
tpl = Template(;
    dir="~/code",
    plugins=[
        Git(; manifest=true, ssh=true),
        Codecov(),
        TravisCI(; x86=true),
        Documenter{TravisCI}(),
    ],
)
```

---

For a much more detailed overview, please see [the User Guide documentation](https://juliaci.github.io/PkgTemplates.jl/stable/user/).

## Contributing

Issues and pull requests are welcome!
New contributors should make sure to read the [ColPrac Contributor Guide](https://github.com/SciML/ColPrac).
For some more PkgTemplates-specific tips, see the [Developer Guide documentation](https://juliaci.github.io/PkgTemplates.jl/stable/developer/).
