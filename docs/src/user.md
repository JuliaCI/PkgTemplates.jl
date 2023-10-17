```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates User Guide

```@contents
Pages = ["user.md"]
```

Using [PkgTemplates](https://github.com/JuliaCI/PkgTemplates.jl/) is straightforward.
Just create a [`Template`](@ref), and call it on a package name to generate that package:

```julia
using PkgTemplates
t = Template()
t("MyPkg")
```

## Template

```@docs
Template
generate
```

## Plugins

Plugins add functionality to `Template`s.
There are a number of plugins available to automate common boilerplate tasks.

### Default Plugins

These plugins are included by default.
They can be overridden by supplying another value, or disabled by negating the type (`!Type`), both as elements of the `plugins` keyword.

```@docs
ProjectFile
SrcDir
Tests
Readme
License
Git
GitHubActions
CompatHelper
TagBot
Secret
```

### Continuous Integration (CI)

These plugins will create the configuration files of common CI services for you.

```@docs
AppVeyor
CirrusCI
DroneCI
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

These plugins will help you build a documentation website.

```@docs
Documenter
Logo
```

### Badges

These plugins will add badges to the README.

```@docs
BlueStyleBadge
ColPracBadge
PkgEvalBadge
```

### Miscellaneous

```@docs
Dependabot
Develop
Citation
RegisterAction
Formatter
CodeOwners
```

## A More Complicated Example

Here are a few example templates that use the options and plugins explained above.

This one includes plugins suitable for a project hosted on GitHub, and some other customizations:

```julia
Template(;
    user="my-username",
    dir="~/code",
    authors="Acme Corp",
    julia=v"1.1",
    plugins=[
        License(; name="MPL"),
        Git(; manifest=true, ssh=true),
        GitHubActions(; x86=true),
        Codecov(),
        Documenter{GitHubActions}(),
        Develop(),
    ],
)
```

Here's one that works well for projects hosted on GitLab:

```julia
Template(;
    user="my-username",
    host="gitlab.com",
    plugins=[
        GitLabCI(),
        Documenter{GitLabCI}(),
    ],
)
```

## Custom Template Files

!!! note "Templates vs Templating"
    This documentation refers plenty to [`Template`](@ref)s, the package's main type, but it also refers to "template files" and "text templating", which are plaintext files with placeholders to be filled with data, and the technique of filling those placeholders with data, respectively.

    These concepts should be familiar if you've used [Jinja](https://palletsprojects.com/p/jinja) or [Mustache](https://mustache.github.io) (Mustache is the particular flavour used by PkgTemplates, via [Mustache.jl](https://github.com/jverzani/Mustache.jl)).
    Please keep the difference between these two things in mind!

Many plugins support a `file` argument or similar, which sets the path to the template file to be used for generating files.
Each plugin has a sensible default that should make sense for most people, but you might have a specialized workflow that requires a totally different template file.

If that's the case, a basic understanding of [Mustache](https://mustache.github.io)'s syntax is required.
Here's an example template file:

```
Hello, {{{name}}}.

{{#weather}}
It's {{{weather}}} outside.
{{/weather}}
{{^weather}}
I don't know what the weather outside is.
{{/weather}}

{{#has_things}}
I have the following things:
{{/has_things}}
{{#things}}
- Here's a thing: {{{.}}}
{{/things}}

{{#people}}
- {{{name}}} is {{{mood}}}
{{/people}}
```

In the first section, `name` is a key, and its value replaces `{{{name}}}`.

In the second section, `weather`'s value may or may not exist.
If it does exist, then "It's \$weather outside" is printed.
Otherwise, "I don't know what the weather outside is" is printed.
Mustache uses a notion of "truthiness" similar to Python or JavaScript, where values of `nothing`, `false`, or empty collections are all considered to not exist.

In the third section, `has_things`' value is printed if it's truthy.
Then, if the `things` list is truthy (i.e. not empty), its values are each printed on their own line.
The reason that we have two separate keys is that `{{#things}}` iterates over the whole `things` list, even when there are no `{{{.}}}` placeholders, which would duplicate "I have the following things:" `n` times.

The fourth section iterates over the `people` list, but instead of using the `{{{.}}}` placeholder, we have `name` and `mood`, which are keys or fields of the list elements.
Most types are supported here, including `Dict`s and structs.
`NamedTuple`s require you to use `{{{:name}}}` instead of the normal `{{{name}}}`, though.

You might notice that some curlies are in groups of two (`{{key}}`), and some are in groups of three (`{{{key}}}`).
Whenever we want to subtitute in a value, using the triple curlies disables HTML escaping, which we rarely want for the types of files we're creating.
If you do want escaping, just use the double curlies.
And if you're using different delimiters, for example `<<foo>>`, use `<<&foo>>` to disable escaping.

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
    @eval begin
        using PkgTemplates
        Template(; #= ... =#)
    end
end
```

Add this to your `startup.jl`, and you can create your template from anywhere, without incurring any startup cost.

Another strategy is to write the string representation of the template to a Julia file:

```julia
const t = Template(; #= ... =#)
open("template.jl", "w") do io
    println(io, "using PkgTemplates")
    sprint(show, io, t)
end
```

Then the template is just an `include` away:

```julia
const t = include("template.jl")
```

The only disadvantage to this approach is that the saved template is much less human-readable than code you wrote yourself.

One more method of saving templates is to simply use the Serialization package in the standard library:

```julia
const t = Template(; #= ... =#)
using Serialization
open(io -> serialize(io, t), "template.bin", "w")
```

Then simply `deserialize` to load:

```julia
using Serialization
const t = open(deserialize, "template.bin")
```

This approach has the same disadvantage as the previous one, and the serialization format is not guaranteed to be stable across Julia versions.
