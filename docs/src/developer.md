```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates Developer Guide

```@contents
Pages = ["developer.md"]
```

PkgTemplates can be easily extended by adding new [`Plugin`](@ref)s.

There are two types of plugins: [`Plugin`](@ref) and [`BasicPlugin`](@ref).

```@docs
Plugin
BasicPlugin
```

## `Plugin` Walkthrough

Concrete types that subtype [`Plugin`](@ref) directly are free to do almost anything.
To understand how they're implemented, let's look at a simplified version of [`Documenter`](@ref):

```julia
@with_kw_noshow struct Documenter <: Plugin
    make_jl::String = default_file("make.jl")
    index_md::String = default_file("index.md")
end

gitignore(::Documenter) = ["/docs/build/", "/docs/site/"]

badges(::Documenter) = [
    Badge(
        "Stable",
        "https://img.shields.io/badge/docs-stable-blue.svg",
        "https://{{USER}}.github.io/{{PKG}}.jl/stable",
    ),
    Badge(
        "Dev",
        "https://img.shields.io/badge/docs-dev-blue.svg",
        "https://{{USER}}.github.io/{{PKG}}.jl/dev",
    ),
]

view(p::Documenter, t::Template, pkg::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "PKG" => pkg,
    "REPO" => "$(t.host)/$(t.user)/$pkg.jl",
    "USER" => t.user,
)

function hook(p::Documenter, t::Template, pkg_dir::AbstractString)
    pkg = basename(pkg_dir)
    docs_dir = joinpath(pkg_dir, "docs")

    make = render_file(p.make_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "make.jl"), make)
    
    index = render_file(p.index_md, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(docs_dir, "src", "index.md"), index)

    # What this function does is not relevant here.
    create_documentation_project()
end
```

First of all, `@with_kw_noshow` comes from [Parameters.jl](https://github.com/mauro3/Parameters.jl), and it just defines a nice keyword constructor for us.
The default values for our type are using [`default_file`](@ref) to point to files in this repository.

```@docs
default_file
```

The first method we implement for `Documenter` is [`gitignore`](@ref), so that packages created with this plugin ignore documentation build artifacts.

```@docs
gitignore
```

Second, we implement [`badges`](@ref) to add a couple of badges to new packages' README files.

```@docs
badges
Badge
```

Third, we implement [`view`](@ref), which is used to fill placeholders in badges and rendered files.

```@docs
view
```

Finally, we implement [`hook`](@ref), which is the real workhorse for the plugin.

TODO prehook and posthook in examples
TODO priority

```@docs
prehook
hook
posthook
```

Inside of this function, we call a few more functions, which help us with text templating.

```@docs
render_file
render_text
gen_file
combined_view
tags
```

TODO more

## `BasicPlugin` Walkthrough

Plugins that subtype [`BasicPlugin`](@ref) perform a much more limited task.
In general, they just generate one templated file.

To illustrate, let's look at the [`Citation`](@ref) plugin, which creates a `CITATION.bib` file.

```julia
@with_kw_noshow struct Citation <: BasicPlugin
    file::String = default_file("CITATION.bib")
end

source(p::Citation) = p.file
destination(::Citation) = "CITATION.bib"

tags(::Citation) = "<<", ">>"

view(::Citation, t::Template, pkg::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "MONTH" => month(today()),
    "PKG" => pkg,
    "URL" => "https://$(t.host)/$(t.user)/$pkg.jl",
    "YEAR" => year(today()),
)
```

Similar to the `Documenter` example above, we're defining a keyword constructor, and assigning a default template file from this repository.
This plugin adds nothing to `.gitignore`, and it doesn't add any badges, so implementations for [`gitignore`](@ref) and [`badges`](@ref) are omitted.

First, we implement [`source`](@ref) and [`destination`](@ref) to define where the template file comes from, and where it goes.
These functions are specific to [`BasicPlugin`](@ref)s, and have no effect on regular [`Plugin`](@ref)s by default.

```@docs
source
destination
```

Next, we implement [`tags`](@ref).
We briefly saw this function earlier, but in this case it's necessary to change its behaviour from the default.
To see why, it might help to see the template file in its entirety:

```
@misc{<<PKG>>.jl,
	author  = {<<AUTHORS>>},
	title   = {<<PKG>>.jl},
	url     = {<<URL>>},
	version = {v0.1.0},
	year    = {<<YEAR>>},
	month   = {<<MONTH>>}
}
```

Because the file contains its own `{}` delimiters, we need to use different ones for templating to work properly.

Finally, we implement [`view`](@ref) to fill in the placeholders that we saw in the template file.

## Doing Extra Work With `BasicPlugin`s

Notice that we didn't have to implement [`hook`](@ref) for our plugin.
It's implemented for all [`BasicPlugin`](@ref)s, like so:

```julia
function render_plugin(p::BasicPlugin, t::Template, pkg::AbstractString)
    return render_file(source(p), combined_view(p, t, pkg), tags(p))
end

function hook(p::BasicPlugin, t::Template, pkg_dir::AbstractString)
    source(p) === nothing && return
    pkg = basename(pkg_dir)
    path = joinpath(pkg_dir, destination(p))
    text = render_plugin(p, t, pkg)
    gen_file(path, text)
end
```

But what if we want to do a little more than just generate one file?

A good example of this is the [`Tests`](@ref) plugin.
It creates `runtests.jl`, but it also modifies the `Project.toml` to include the `Test` dependency.

Of course, we could use a normal [`Plugin`](@ref), but it turns out there's a way to avoid that while still getting the extra capbilities that we want.

The plugin implements its own `hook`, but uses `invoke` to avoid duplicating the file creation code:

```julia
@with_kw_noshow struct Tests <: BasicPlugin
    file::String = default_file("runtests.jl")
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")
view(::Tests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

function hook(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal BasicPlugin behaviour to create the test script.
    invoke(hook, Tuple{BasicPlugin, Template, AbstractString}, p, t, pkg_dir)
    # Do some other work.
    add_test_dependency()
end
```

For more examples, see the plugins in the [Continuous Integration (CI)](@ref) and [Code Coverage](@ref) sections.

## Miscellaneous Tips

### Writing Template Files

For an overview of writing template files for Mustache.jl, see [Custom Template Files](@ref) in the user guide.

### Traits

There are a few traits for plugin types that are occassionally used to answer questions like "does this `Template` have any code coverage plugins?".
If you're implementing a plugin that fits into one of the following categories, it would be wise to implement the corresponding trait function to return `true` for your type.

```@docs
is_ci
is_coverage
```

### Formatting Version Numbers

When writing configuration files for CI services, working with version numbers is often needed.
There are a few convenience functions that can be used to make this a little bit easier.

```@docs
compat_version
format_version
collect_versions
```
