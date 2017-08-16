# Contributing to PkgTemplates

The best way to contribute to `PkgTemplates` is by adding new plugins.

Plugins are pretty simple. They're defined as subtypes to `Plugin`, in their
own file inside `src/plugins`. Let's create one, called `MyPlugin`, in
`src/plugins/myplugin.jl`:

```julia
@auto_hash_equals struct MyPlugin <: Plugin end
```

The `@auto_hash_equals` macro means we don't have to implement `==` or `hash`
ourselves ([ref](https://github.com/andrewcooke/AutoHashEquals.jl)).

All plugins need at least one attribute: `gitignore_files`. This is a
`Vector{AbstractString}`, of which each entry will be inserted in the
`.gitignore` of generated packages that use this plugin.

Maybe the service that `MyPlugin` is associated with creates a directory
called `secrets`, containing top secret data. In that case, `gitignore_files`
should contain that string:

```julia
@auto_hash_equals struct MyPlugin <: Plugin
    gitignore_files::Vector{AbstractString}

    function MyPlugin()
        new(["/secrets"])
    end
end
```

You can also add patterns like `*.key`, etc. to this array. Note that Windows
Git also recognizes `/` as a path separator in `.gitignore`, so there's no
pneed for `joinpath`.

Suppose that `MyPlugin` also has a configuration file at the root of the repo.
We're going to put a default `myplugin.yml` in `defaults`, but we also want
to let users supply their own, or choose to not use one at all:

```julia
@auto_hash_equals struct MyPlugin <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function MyPlugin(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "myplugin.yml")
            end
            if !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(["/secrets"], config_file)
    end
end
```

Now to actually create this configuration file at package generation time,
we need a `gen_plugin` method. This method looks like this:

```julia
function gen_plugin(plugin::MyPlugin, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    gen_file(joinpath(template.temp_dir, pkg_name, ".myplugin.yml"))
    return [".myplugin.yml"]
end
```

There are a few things to note here:

* We use the `substitute` function on the config file's text.
  * More on that [later](#template-substitution).
* We use the `gen_file` function to create the file.
  * It takes two arguments: the path to the file to be generated,
    and the text to be written.
* We place our file in `template.temp_dir`.
  * `template.temp_dir` is where all file generation takes place, files are
    only moved to their final location at the end of package generation
    to avoid leftovers in the case of an error.
* We return an array containing at most the name of our generated file.
  * This array should contain all root-level files or directories that were
    created. If we created `myplugin/foo` and `myplugin/bar`, we'd only need
    to return `["myplugin/"]`. If nothing is created, then we return an
    empty array.

We've got the essentials now, but perhaps `MyPlugin` has a web interface
that we want to access from the repo's homepage. We'll do this by adding a
badge to the README:

```julia
function badges(_::MyPlugin, user::AbstractString, pkg_name::AbstractString)
    return [
        "[![MyPlugin](https://myplugin.com/badges/$user/$pkg_name.jl)](https://myplugin.com/$user/$pkg_name.jl)"
    ]
end
```

This method should return an array of Markdown-formatted strings that display
badges and link to somewhere relevant. Note that a plugin can have any number
of badges. The Markdown syntax is as follows:

```
[![Hover Text](https://badge-image.url)](https://link.url)
```

Badges for just about everything can be found at
[Shields.io](https://shields.io/).

We're not done yet though, we need to add the plugin type to the list of
badge-enabled plugins. We want `MyPlugin`'s badge to be displayed on the far
right side, so we're going to add `MyPlugin` to the end of `BADGE_ORDER` in
`src/PkgTemplates.jl`.

```julia
const BADGE_ORDER = [GitHubPages, TravisCI, AppVeyor, CodeCov, MyPlugin]
```

And we're done! We've just created a nifty new plugin.

***

### Template Substitution

Since plugin configuration files are often specific to the package they belong
to, we might want to replace some placeholder values in our plugin's config
file. We can do this by following
[Mustache.jl](https://github.com/jverzani/Mustache.jl)'s rules. Some
replacements are defined by `PkgTemplates`:

* `{{PKGNAME}}` is replaced by `pkg_name`.
* `{{VERSION}}` is replaced by `$major.$minor` corresponding to
  `template.julia_version`.

Some conditional replacements are also defined:

* `{{DOCUMENTER}}Documenter{{/DOCUMENTER}}`
  * "Documenter" only appears in the rendered text if the template contains
    a [`Documenter`](src/plugins/documenter.jl) subtype.
* `{{CODECOV}}CodeCov{{/CODECOV}}`
  * "CodeCov" only appears in the rendered text if the template contains
    the [`CodeCov`](src/plugins/codecov.jl) plugin.
* `{{#AFTER}}After{{/AFTER}}`
  * "After" only appears in the rendered text if something needs to happen
    **after** CI testing occurs. As of right now, this is true when either of
    the above two conditions are true.

We can also specify our own replacements by passing a dictionary to
`substitute`:

```julia
view = Dict("KEY" => "VAL", "HEADS" => 2rand() > 1)
text = """
    {{KEY}}
    {{PKGNAME}}
    {{#HEADS}}Heads{{/HEADS}}
    """
substituted = substitute(text, "MyPkg", template; view=view)
```

This will return `"VAL\nMyPkg\nHeads\n"` if `2rand() > 1` was true,
`"VAL\nMyPkg\n\n"` otherwise.

Note the double newline in the second outcome; `Mustache` has a bug with
conditionals that inserts extra newlines (more detail
[here](https://github.com/jverzani/Mustache.jl/issues/47)). We can get around
this by writing ugly template files, like so:

```
{{KEY}}
{{PKGNAME}}{{#HEADS}}
Heads{{/HEADS}}
```

The resulting string will end with a single newline regardless of the value
of `view["HEADS"]`

Also note that conditionals without a corresponding key in `view` won't error,
but will simply be evaluated as false.
