# PkgTemplates

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/PkgTemplates.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/PkgTemplates.jl/latest)
[![Build Status](https://travis-ci.org/invenia/PkgTemplates.jl.svg?branch=master)](https://travis-ci.org/invenia/PkgTemplates.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/r24xamruqlm88uti/branch/master?svg=true)](https://ci.appveyor.com/project/christopher-dG/pkgtemplates-jl/branch/master)
[![CodeCov](https://codecov.io/gh/invenia/PkgTemplates.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PkgTemplates.jl)

**PkgTemplates is a Julia package for creating new Julia packages in an easy,
repeatable, and customizable way.**

## Installation

```julia
(v1.0) pkg> add PkgTemplates
```

## Usage

The simplest template requires no arguments.

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
  → Plugins: None

julia> generate("MyPkg", t)
Generating project MyPkg:
    /Users/degraafc/.julia/dev/MyPkg/Project.toml
    /Users/degraafc/.julia/dev/MyPkg/src/MyPkg.jl
[ Info: Initialized git repo at /Users/degraafc/.julia/dev/MyPkg
[ Info: Set remote origin to https://github.com/myusername/MyPkg.jl
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
 Resolving package versions...
  Updating `~/.julia/dev/MyPkg/Project.toml`
  [8dfed614] + Test
  Updating `~/.julia/dev/MyPkg/Manifest.toml`
  [2a0f44e3] + Base64
  [8ba89e20] + Distributed
  [b77e0a4c] + InteractiveUtils
  [8f399da3] + Libdl
  [37e2e46d] + LinearAlgebra
  [56ddb016] + Logging
  [d6f4376e] + Markdown
  [9a3f8284] + Random
  [9e88b42a] + Serialization
  [6462fe0b] + Sockets
  [8dfed614] + Test
[ Info: Staged and committed 8 files/directories: src/, Project.toml, Manifest.toml, test/, REQUIRE, README.md, .gitignore, LICENSE
[ Info: Finished

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
           dir=joinpath(homedir(), "code"),
           julia_version=v"0.7",
           plugins=[
               TravisCI(),
               CodeCov(),
               Coveralls(),
               AppVeyor(),
               GitHubPages(),
           ],
       )
Template:
  → User: myusername
  → Host: github.com
  → License: ISC (Chris de Graaf, Invenia Technical Computing Corporation 2018)
  → Package directory: ~/code
  → Minimum Julia version: v0.7
  → SSH remote: No
  → Plugins:
    • AppVeyor:
      → Config file: Default
      → 0 gitignore entries
    • CodeCov:
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
Generating project MyPkg2:
    /Users/degraafc/code/MyPkg2/Project.toml
    /Users/degraafc/code/MyPkg2/src/MyPkg2.jl
[ Info: Initialized git repo at /Users/degraafc/code/MyPkg2
[ Info: Set remote origin to https://github.com/myusername/MyPkg2.jl
[ Info: Created empty gh-pages branch
 Resolving package versions...
  Updating `~/code/MyPkg2/Project.toml`
  [8dfed614] + Test
  Updating `~/code/MyPkg2/Manifest.toml`
  [2a0f44e3] + Base64
  [8ba89e20] + Distributed
  [b77e0a4c] + InteractiveUtils
  [8f399da3] + Libdl
  [37e2e46d] + LinearAlgebra
  [56ddb016] + Logging
  [d6f4376e] + Markdown
  [9a3f8284] + Random
  [9e88b42a] + Serialization
  [6462fe0b] + Sockets
  [8dfed614] + Test
[ Info: Staged and committed 11 files/directories: src/, Project.toml, Manifest.toml, test/, REQUIRE, README.md, .gitignore, LICENSE, .appveyor.yml, .travis.yml, docs/
[ Info: Finished
[ Info: Remember to push all created branches to your remote: git push --all

julia> run(`git -C $(joinpath(t.dir, "MyPkg2")) ls-files`);
.appveyor.yml
.gitignore
.travis.yml
LICENSE
Manifest.toml
Project.toml
README.md
REQUIRE
docs/make.jl
docs/src/index.md
src/MyPkg2.jl
test/runtests.jl
```

Information on each keyword as well as plugin types can be found in the
[documentation](https://invenia.github.io/PkgTemplates.jl/stable).

If that looks like a lot of work, you can also create templates interactively
with `interactive_template`:

[![asciicast](https://asciinema.org/a/bqBwff05mI7Cl9bz7EqLPMKF8.png)](https://asciinema.org/a/bqBwff05mI7Cl9bz7EqLPMKF8)

And if that's **still** too much work for you, you can call
`interactive_template` with `fast=true` to use default values for everything
but username and plugin selection.

You can also use `generate_interactive` to interactively generate a template and then
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
