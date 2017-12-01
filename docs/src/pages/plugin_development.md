```@meta
CurrentModule = PkgTemplates
```

# Plugin Development

The best and easiest way to contribute to `PkgTemplates` is to write new
plugins.

```@docs
Plugin
```

## Generic Plugins

```@docs
GenericPlugin
```

## Custom Plugins

```@docs
CustomPlugin
```

### `CustomPlugin` Required Methods

#### `gen_plugin`

```@docs
gen_plugin
interactive
```

**Note**: [`interactive`](@ref) is not strictly required, however without it,
your custom plugin will not be available when creating templates with
[`interactive_template`](@ref).

#### `badges`

```@docs
badges
```

## Helper Types/Functions

#### `gen_file`

```@docs
gen_file
```

#### `substitute`

```@docs
substitute
```

#### `Badge`

```@docs
Badge
```

#### `format`

```@docs
format
```

#### `version_floor`

```@docs
version_floor
```
