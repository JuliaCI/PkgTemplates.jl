```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates User Guide

```@contents
Pages = ["user.md"]
```

Using PkgTemplates is straightforward.
Just create a [`Template`](@ref), and call it on a package name to generate that package.

## Template

```@docs
Template
```

## Plugins

Plugins add functionality to `Template`s.
There are a number of plugins available to automate common boilerplate tasks.

### Defaults

These plugins are included by default.
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

## Custom Template Files

Many plugins support a `file` argument or similar, which sets the path to the template file to be used for generating files.
Each plugin has a sensible default that should make sense for most people, but you might have a specialized workflow that requires a totally different template file.

If that's the case, a basic understanding of [Mustache](https://mustache.github.io)'s syntax is required.
Here's an example template file:

```
Hello, {{name}}.

{{#weather}}
It's {{weather}} outside. 
{{/weather}}
{{^weather}}
I don't know what the weather outside is.
{{/weather}}

{{#has_things}}
I have the following things:
{{/has_things}}
{{#things}}
- Here's a thing: {{.}}
{{/things}}

{{#people}}
- {{name}} is {{mood}}
{{/people}}
```

In the first section, `name` is a key, and its value replaces `{{name}}`.

In the second section, `weather`'s value may or may not exist.
If it does exist, then "It's $weather outside" is printed.
Otherwise, "I don't know what the weather outside is" is printed.
Mustache uses a notion of "truthiness" similar to Python or JavaScript, where values of `nothing`, `false`, or empty collections are all considered to not exist.

In the third section, `has_things`' value is printed if it's truthy.
Then, if the `things` list is truthy (i.e. not empty), its values are each printed on their own line.
The reason that we have two separate keys is that `{{#things}}` iterates over the whole `things` list, even when there are no `{{.}}` placeholders, which would duplicate "I have the following things:" `n` times.

The fourth section iterates over the `people` list, but instead of using the `{{.}}` placeholder, we have `name` and `mood`, which are keys or fields of the list elements.
Most types are supported here, including `Dict`s and structs.
`NamedTuple`s require you to use `{{:name}}` instead of the normal `{{name}}`, though.

Assuming the following view:

```julia
struct Person; name::String; mood::String; end
things = ["a", "b", "c"]
view = Dict(
    "name" => "Chris",
    "weather" => "sunny",
    "has_things" => !isempty(things),
    "things" => things,
    "people" => [Person("John", "happy"), Person("Jane", "sad")],
)
```

Our example template would produce this:

```
Hello, Chris.

It's sunny outside.

I have the following things:
- Here's a thing: a
- Here's a thing: b
- Here's a thing: c

- John is happy
- Jane is sad
```

## Extending Existing Plugins

Most of the existing plugins generate a file from a template file.
If you want to use custom template files, you may run into situations where the data passed into the templating engine is not sufficient.
In this case, you can look into implementing [`user_view`](@ref) to supply whatever data is necessary for your use case.

```@docs
user_view
```

For example, suppose you were using the [`Readme`](@ref) plugin with a custom template file that looked like this:

```md
# {{PKG}}

Created on *{{TODAY}}*.
```

The [`view`](@ref) function supplies a value for `PKG`, but it does not supply a value for `TODAY`.
Rather than override [`view`](@ref), we can implement this function to get both the default values and whatever else we need to add.

```julia
user_view(::Readme, ::Template, ::AbstractString) = Dict("TODAY" => today())
```

## Saving Templates

One of the main reasons for PkgTemplates' existence is for new packages to be consistent.
This means using the same template more than once, so we want a way to save a template to be used later.

Here's my recommendation for loading a template whenever it's needed:

```julia
function template()
    @eval using PkgTemplates
    Template(; #= ... =#)
end
```

Add this to your `startup.jl`, and you can create your template from anywhere, without incurring any startup cost.
