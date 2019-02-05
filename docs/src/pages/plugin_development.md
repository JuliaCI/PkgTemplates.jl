```@meta
CurrentModule = PkgTemplates
```

# Plugin Development

The best and easiest way to contribute to `PkgTemplates` is to write new plugins.

```@docs
Plugin
```

## "Generic" Plugins

Many plugins fall into the category of managing some configuration file.
Think Travis CI's `.travis.yml`, and so on for every CI service ever.
For these one-file plugins, a shortcut macro is available to define a plugin in one line.

```@docs
GeneratedPlugin
@plugin
```

### `GeneratedPlugin` Customization

When you generate a plugin type with [`@plugin`](@ref), all required methods are
implemented for you. However, you're still allowed to override behaviour if you so desire.
These are the relevant methods:

```@docs
source
destination
gitignore
badges
view
```

For some examples, see
[`generated.jl`](https://github.com/invenia/PkgTemplates.jl/tree/master/src/plugins/generated.jl).

## Custom Plugins

When a plugin is too complicated to be expressed with [`GeneratedPlugin`](@ref), we only
need to implement a few methods to create something fully custom.

### Required Methods

```@docs
gen_plugin
```

### Optional Methods

```@docs
interactive
```

Additionally, [`gitignore`](@ref), [`badges`](@ref), and [`view`](@ref) can also be
implemented in the same way as for [`GeneratedPlugin`](@ref)s (they have empty default
implementations). [`source`](@ref) and [`destination`](@ref) have no meaning for custom
plugins.

### Helpers

These types and functions will make implementing the above methods much easier.

```@docs
Badge
gen_file
substitute
version_floor
```
