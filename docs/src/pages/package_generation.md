```@meta
CurrentModule = PkgTemplates
```

# Package Generation

Creating new packages with `PkgTemplates` revolves around creating a new
[`Template`](@ref), then calling [`generate`](@ref) on it.

## `Template`

```@docs
Template
interactive_template
```

## `generate`

```@docs
generate
generate_interactive
```

### Helper Functions

```@docs
gen_tests
gen_require
gen_readme
gen_gitignore
gen_license
```
