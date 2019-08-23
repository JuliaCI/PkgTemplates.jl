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

## Plugins

`PkgTemplates` is based on plugins which handle the setup of individual package components.
The available plugins are:

* Continuous Integration (CI)
  * [Travis CI](https://travis-ci.com) (Linux, MacOS)
  * [AppVeyor](https://appveyor.com) (Windows)
  * [GitLabCI](https://gitlab.com) (Linux)
  * [CirrusCI](https://cirrus-ci.org) (FreeBSD)
* Code Coverage
  * [Codecov](https://codecov.io)
  * [Coveralls](https://coveralls.io)
* Documentation
  * [GitHubPages](https://pages.github.com)
* Citation

## Usage

Assuming you have the relatively standard Git options `user.name`, `user.email` and `github.user` set up globally with `git config --global`, the simplest template requires no arguments:

```julia
julia> using PkgTemplates

julia> t = Template()
Template:
  → User: christopher-dG
  → Host: github.com
  → License: MIT (Chris de Graaf 2018)
  → Package directory: ~/.julia/dev
  → Minimum Julia version: v1.0
  → SSH remote: No
  → Commit Manifest.toml: No
  → Plugins: None

julia> generate("MyPkg", t)

julia> run(`git -C $(joinpath(t.dir, "MyPkg")) ls-files`);
.gitignore
LICENSE
Manifest.toml
Project.toml
README.md
REQUIRE
src/MyPkg.jl
test/runtests.jl
```

However, we can also configure a number of keyword arguments to `Template`:

```julia
julia> t = Template(;
           user="myusername",
           license="ISC",
           authors=["Chris de Graaf", "Invenia Technical Computing Corporation"],
           dir="~/code",
           julia_version=v"0.7",
           plugins=[
               TravisCI(),
               Codecov(),
               Coveralls(),
               AppVeyor(),
               GitHubPages(),
               CirrusCI(),
           ],
       )
Template:
  → User: myusername
  → Host: github.com
  → License: ISC (Chris de Graaf, Invenia Technical Computing Corporation 2018)
  → Package directory: ~/code
  → Minimum Julia version: v0.7
  → SSH remote: No
  → Commit Manifest.toml: No
  → Plugins:
    • AppVeyor:
      → Config file: Default
      → 0 gitignore entries
    • Codecov:
      → Config file: None
      → 3 gitignore entries: "*.jl.cov", "*.jl.*.cov", "*.jl.mem"
    • Coveralls:
      → Config file: None
      → 3 gitignore entries: "*.jl.cov", "*.jl.*.cov", "*.jl.mem"
    • GitHubPages:
      → 0 asset files
      → 2 gitignore entries: "/docs/build/", "/docs/site/"
    • TravisCI:
      → Config file: Default
      → 0 gitignore entries

julia> generate(t, "MyPkg2")

julia> run(`git -C $(joinpath(t.dir, "MyPkg2")) ls-files`);
.appveyor.yml
.gitignore
.travis.yml
LICENSE
Project.toml
README.md
REQUIRE
docs/Manifest.toml
docs/Project.toml
docs/make.jl
docs/src/index.md
src/MyPkg2.jl
test/runtests.jl
```

Information on each keyword as well as plugin types can be found in the
[documentation](https://invenia.github.io/PkgTemplates.jl/stable).

If that looks like a lot of work, you can also create templates interactively
with `interactive_template`:

[![asciicast](https://asciinema.org/a/31bZqW9u8h5RHpd7gtsemioRV.png)](https://asciinema.org/a/31bZqW9u8h5RHpd7gtsemioRV)

And if that's **still** too much work for you, you can call
`interactive_template` with `fast=true` to use default values for everything
but username and plugin selection.

You can also use `generate_interactive` to interactively generate a template and then
immediately use it to create a new package.

## Contributing

It's extremely easy to extend `PkgTemplates` with new plugins. To get started,
check out the
[plugin development guide](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugin_development.html).
