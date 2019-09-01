```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates Developer Guide

PkgTemplates can be easily extended by adding new [`Plugin`](@ref)s.

## The `Plugin` Interface

```@docs
gen_plugin
gitignore
badges
Badge
view
user_view
combined_view
tags
```

## The `BasicPlugin` Interface

While subtyping [`Plugin`](@ref) gives you complete freedom, it's not always necessary.
For more constrained cases, a simpler API exists.

```@docs
BasicPlugin
source
destination
```
