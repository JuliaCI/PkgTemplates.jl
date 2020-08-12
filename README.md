# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/PkgTemplates.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/PkgTemplates.jl/dev)
[![Build Status](https://github.com/invenia/PkgTemplates.jl/workflows/CI/badge.svg)](https://github.com/invenia/PkgTemplates.jl/actions)
[![Codecov](https://codecov.io/gh/invenia/PkgTemplates.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PkgTemplates.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

**PkgTemplates creates new Julia packages in an easy, repeatable, and customizable way.**

## Installation

Install with Pkg, just like any other registered Julia package:

```jl
pkg> add PkgTemplates  # Press ']' to enter the Pkg REPL mode.
```

## Usage

Creating a `Template` is as simple as:

```jl
using PkgTemplates
t = Template()
```

The no-keywords constructor assumes the existence of some preexisting Git configuration (set with `git config --global`):

- `user.name`: Your real name, e.g. John Smith.
- `user.email`: Your email address, eg. john.smith@acme.corp.
- `github.user`: Your GitHub username: e.g. john-smith.

Once you have a `Template`, use it to generate a package:

```jl
t("MyPkg")
```

However, it's probably desirable to customize the template to your liking with various options and plugins:

```jl
t = Template(;
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

For a much more detailled overview, please see the documentation.

## Contributing

Issues and pull requests are welcome!
For some more specific tips, see the developer documentation.
