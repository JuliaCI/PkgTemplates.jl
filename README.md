# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/PkgTemplates.jl/stable)
[![Dev](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/PkgTemplates.jl/dev)
[![Build Status](https://travis-ci.org/invenia/PkgTemplates.jl.svg?branch=master)](https://travis-ci.org/invenia/PkgTemplates.jl)
[![Codecov](https://codecov.io/gh/invenia/PkgTemplates.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PkgTemplates.jl)

**PkgTemplates creates new Julia packages in an easy, repeatable, and customizable way.**

## Usage

Assuming you have the relatively standard Git options `user.name`, `user.email` and `github.user` set up globally with `git config --global`, creating a `Template` is as simple as:

```jl
using PkgTemplates
t = Template()
```

However, it's probably desirable to customize the template to your liking with various options and plugins:

```jl
t = Template(;
    dir="~/code",
    ssh=true,
    manifest=true,
    plugins=[
        Codecov(),
        TravisCI(; x86=true),
        Documenter{TravisCI}(),
    ],
)
```

Once you have a `Template`, yoy can createa packages with ease:

```jl
t("MyPkg")
```

---

For a much more detailled overview, please see the documentation.
