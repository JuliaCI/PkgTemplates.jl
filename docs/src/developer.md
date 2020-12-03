```@meta
CurrentModule = PkgTemplates
```

# PkgTemplates Developer Guide

```@contents
Pages = ["developer.md"]
```

PkgTemplates can be easily extended by adding new [`Plugin`](@ref)s.

There are three types of plugins: [`Plugin`](@ref), [`FilePlugin`](@ref), and [`BadgePlugin`](@ref).

```@docs
Plugin
FilePlugin
BadgePlugin
```

## Template + Package Creation Pipeline

The [`Template`](@ref) constructor basically does this:

```
- extract values from keyword arguments
- create a Template from the values
- for each plugin:
  - validate plugin against the template
```

The plugin validation step uses the [`validate`](@ref) function.
It lets us catch mistakes before we try to generate packages.

```@docs
validate
```

The package generation process looks like this:

```
- create empty directory for the package
- for each plugin, ordered by priority:
  - run plugin prehook
- for each plugin, ordered by priority:
  - run plugin hook
- for each plugin, ordered by priority:
  - run plugin posthook
```

As you can tell, plugins play a central role in setting up a package.

The three main entrypoints for plugins to do work are the [`prehook`](@ref), the [`hook`](@ref), and the [`posthook`](@ref).
As the names might imply, they basically mean "before the main stage", "the main stage", and "after the main stage", respectively.

Each stage is basically identical, since the functions take the exact same arguments.
However, the multiple stages allow us to depend on artifacts of the previous stages.
For example, the [`Git`](@ref) plugin uses [`posthook`](@ref) to commit all generated files, but it wouldn't make sense to do that before the files are generated.

But what about dependencies within the same stage?
In this case, we have [`priority`](@ref) to define which plugins go when.
The [`Git`](@ref) plugin also uses this function to lower its posthook's priority, so that even if other plugins generate files in their posthooks, they still get committed (provided that those plugins didn't set an even lower priority).

```@docs
prehook
hook
posthook
priority
```

## `Plugin` Walkthrough

Concrete types that subtype [`Plugin`](@ref) directly are free to do almost anything.
To understand how they're implemented, let's look at simplified versions of two plugins: [`Documenter`](@ref) to explore templating, and [`Git`](@ref) to further clarify the multi-stage pipeline.

### Example: `Documenter`

```julia
@plugin struct Documenter <: Plugin
    make_jl::String = default_file("docs", "make.jl")
    index_md::String = default_file("docs", "src", "index.md")
end

gitignore(::Documenter) = ["/docs/build/"]

badges(::Documenter) = [
    Badge(
        "Stable",
        "https://img.shields.io/badge/docs-stable-blue.svg",
        "https://{{{USER}}}.github.io/{{{PKG}}}.jl/stable",
    ),
    Badge(
        "Dev",
        "https://img.shields.io/badge/docs-dev-blue.svg",
        "https://{{{USER}}}.github.io/{{{PKG}}}.jl/dev",
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

The `@plugin` macro defines some helpful methods for us.
Inside of our struct definition, we're using [`default_file`](@ref) to refer to files in this repository.

```@docs
@plugin
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

These two functions, [`gitignore`](@ref) and [`badges`](@ref), are currently the only "special" functions for cross-plugin interactions.
In other cases, you can still access the [`Template`](@ref)'s plugins to depend on the presence/properties of other plugins via [`getplugin`](@ref), although that's less powerful.

```@docs
getplugin
```

Third, we implement [`view`](@ref), which is used to fill placeholders in badges and rendered files.

```@docs
view
```

Finally, we implement [`hook`](@ref), which is the real workhorse for the plugin.
Inside of this function, we generate a couple of files with the help of a few more text templating functions.

```@docs
render_file
render_text
gen_file
combined_view
tags
```

For more information on text templating, see the [`FilePlugin` Walkthrough](@ref) and the section on [Custom Template Files](@ref).

### Example: `Git`

```julia
struct Git <: Plugin end

priority(::Git, ::typeof(posthook)) = 5

function validate(::Git, ::Template)
    foreach(("user.name", "user.email")) do k
        if isempty(LibGit2.getconfig(k, ""))
            throw(ArgumentError("Git: Global Git config is missing required value '$k'"))
        end
    end
end

function prehook(::Git, t::Template, pkg_dir::AbstractString)
    LibGit2.with(LibGit2.init(pkg_dir)) do repo
        LibGit2.commit(repo, "Initial commit")
        pkg = basename(pkg_dir)
        url = "https://$(t.host)/$(t.user)/$pkg.jl"
        close(GitRemote(repo, "origin", url))
    end
end

function hook(::Git, t::Template, pkg_dir::AbstractString)
    ignore = mapreduce(gitignore, append!, t.plugins)
    unique!(sort!(ignore))
    gen_file(joinpath(pkg_dir, ".gitignore"), join(ignore, "\n"))
end

function posthook(::Git, ::Template, pkg_dir::AbstractString)
    LibGit2.with(GitRepo(pkg_dir)) do repo
        LibGit2.add!(repo, ".")
        LibGit2.commit(repo, "Files generated by PkgTemplates")
    end
end
```

We didn't use `@plugin` for this one, because there are no fields.
Validation and all three hooks are implemented:

- [`validate`](@ref) makes sure that all required Git configuration is present.
- [`prehook`](@ref) creates the Git repository for the package.
- [`hook`](@ref) generates the `.gitignore` file, using the special [`gitignore`](@ref) function.
- [`posthook`](@ref) adds and commits all the generated files.

As previously mentioned, we use [`priority`](@ref) to make sure that we wait until all other plugins are finished their work before committing files.

Hopefully, this demonstrates the level of control you have over the package generation process when developing plugins, and when it makes sense to exercise that power!

## `FilePlugin` Walkthrough

Most of the time, you don't really need all of the control that we showed off above.
Plugins that subtype [`FilePlugin`](@ref) perform a much more limited task.
In general, they just generate one templated file.

To illustrate, let's look at the [`Citation`](@ref) plugin, which creates a `CITATION.bib` file.

```julia
@plugin struct Citation <: FilePlugin
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
These functions are specific to [`FilePlugin`](@ref)s, and have no effect on regular [`Plugin`](@ref)s by default.

```@docs
source
destination
```

Next, we implement [`tags`](@ref).
We briefly saw this function earlier, but in this case it's necessary to change its behaviour from the default.
To see why, it might help to see the template file in its entirety:

```
@misc{<<&PKG>>.jl,
	author  = {<<&AUTHORS>>},
	title   = {<<&PKG>>.jl},
	url     = {<<&URL>>},
	version = {v0.1.0},
	year    = {<<&YEAR>>},
	month   = {<<&MONTH>>}
}
```

Because the file contains its own `{}` delimiters, we need to use different ones for templating to work properly.

Finally, we implement [`view`](@ref) to fill in the placeholders that we saw in the template file.

## Doing Extra Work With `FilePlugin`s

Notice that we didn't have to implement [`hook`](@ref) for our plugin.
It's implemented for all [`FilePlugin`](@ref)s, like so:

```julia
function render_plugin(p::FilePlugin, t::Template, pkg::AbstractString)
    return render_file(source(p), combined_view(p, t, pkg), tags(p))
end

function hook(p::FilePlugin, t::Template, pkg_dir::AbstractString)
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
@plugin struct Tests <: FilePlugin
    file::String = default_file("runtests.jl")
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")
view(::Tests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)

function hook(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal FilePlugin behaviour to create the test script.
    invoke(hook, Tuple{FilePlugin, Template, AbstractString}, p, t, pkg_dir)
    # Do some other work.
    add_test_dependency()
end
```

There is also a default [`validate`](@ref) implementation for [`FilePlugin`](@ref)s, which checks that the plugin's [`source`](@ref) file exists, and throws an `ArgumentError` otherwise.
If you want to extend the validation but keep the file existence check, use the `invoke` method as described above.

For more examples, see the plugins in the [Continuous Integration (CI)](@ref) and [Code Coverage](@ref) sections.

## Supporting Interactive Mode

When it comes to supporting interactive mode for your custom plugins, you have two options: write your own [`interactive`](@ref) method, or use the default one.
If you choose the first option, then you are free to implement the method however you want.
If you want to use the default implementation, then there are a few functions that you should be aware of, although in many cases you will not need to add any new methods.

```@docs
interactive
prompt
customizable
input_tips
convert_input
```

## Miscellaneous Tips

### Writing Template Files

For an overview of writing template files for Mustache.jl, see [Custom Template Files](@ref) in the user guide.

### Predicates

There are a few predicate functions for plugins that are occasionally used to answer questions like "does this `Template` have any code coverage plugins?".
If you're implementing a plugin that fits into one of the following categories, it would be wise to implement the corresponding predicate function to return `true` for instances of your type.

```@docs
needs_username
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

## Testing

If you write a cool new plugin that could be useful to other people, or find and fix a bug, you're encouraged to open a pull request with your changes.
Here are some testing tips to ensure that your PR goes through as smoothly as possible.

### Updating Reference Tests & Fixtures

If you've added or modified plugins, you should update the reference tests and the associated test fixtures.
In `test/reference.jl`, you'll find a "Reference tests" test set that basically generates a bunch of packages, and then checks each file against a reference file, which is stored somewhere in `test/fixtures`.

For new plugins, you should add an instance of your plugin to the "All plugins" and "Wacky options" test sets, then run the tests with `Pkg.test`.
They should pass, and there will be new files in `test/fixtures`.
Check them to make sure that they contain exactly what you would expect!

For changes to existing plugins, update the plugin options appropriately in the "Wacky options" test set.
Failing tests  will give you the option to review and accept changes to the fixtures, updating the files automatically for you.

### Updating "Show" Tests

Depending on what you've changed, the tests in `test/show.jl` might fail.
To fix those, you'll need to update the `expected` value to match what is actually displayed in a Julia REPL (assuming that the new value is correct).
