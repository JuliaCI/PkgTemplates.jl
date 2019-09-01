```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates User Guide

Using PkgTemplates is straightforward.
Just create a [`Template`](@ref), and call it on a package name to generate that package.

## Template

```@docs
Template
```

## Plugins

Plugins are PkgTemplates' source of customization and extensibility.
Add plugins to your templates to enable extra pieces of repository setup.

```@docs
Plugin
```

### Defaults

These plugins are included in [`Template`](@ref)s by default.
They can be overridden by supplying another value via the `plugins` keyword, or disabled by supplying the type via the `disable_defaults` keyword.

```@docs
Gitignore
License
Readme
Tests
```

### Continuous Integration (CI)

These plugins will create the configuration files of common CI services for you.

```@docs
AppVeyor
CirrusCI
GitLabCI
TravisCI
```

### Code Coverage

These plugins will enable code coverage reporting from CI.

```@docs
Codecov
Coveralls
```

### Documentation

```@docs
Documenter
```

### Miscellaneous

```@docs
Citation
```
