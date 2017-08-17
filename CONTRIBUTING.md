# Contributing to PkgTemplates

The best way to contribute to `PkgTemplates` is by adding new plugins.

There are two main types of plugins:
[`GenericPlugin`](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugins.html#GenericPlugin-1)s
and
[`CustomPlugin`](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugins.html#CustomPlugin-1)s.

## Writing a Generic Plugin

As the name suggests, generic plugins are simpler than custom ones, and as
such are extremely easy to implement. They have the ability to add patterns
the the generated `.gitignore`, as well as create a single configuration file.
We're going to define a new generic plugin `MyPlugin` in
`src/plugins/myplugin.jl`:

```julia
@auto_hash_equals struct MyPlugin <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{AbstractString}
    view::Dict{String, Any}

    function MyPlugin(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "myplugin.yml")
            elseif !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new([], config_file, ".myplugin.yml", [], Dict{String, Any}())
    end
end
```

That's all there is to it! Let's take a better look at what we've done:

* The plugin has five attributes, these must be exactly as they are.
  * `gitignore` is the array of patterns to add the the generated package's
    `.gitignore`, we chose not to add any with this plugin.
  * `src` is the location of the config file we're going to copy into the
    generated package repository. If this is `nothing`, no config file will be
    generated. This came from the `config_file` keyword argument, which
    defaulted to an empty string. That's because we've placed a default
    config file at `defaults/myplugin.yml`.
  * `dest` is the path to our generated config file, relative to the root of
    the package repository. In this example, the file will go in
    `.myplugin.yml` at the root of the repository.
  * `badges` is an array of Markdown-formatted badge strings to be displayed
    on the package's README. We chose not to include any here. TODO talk about
    `substitute`.
  * `view` is a dictionary of additional replacements to `substitute`.

Plenty of services like
[`TravisCI`](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugins.html#TravisCI-1)
and
[`CodeCov`](https://invenia.github.io/PkgTemplates.jl/stable/pages/plugins.html#CodeCov-1)
follow this format, so generic plugins should be able to get you pretty far.

## Writing a Custom Plugin

When a service doesn't follow the pattern demonstrated above, it's time to write a custom
plugin. These are still pretty simple, needing at most two additional methods. Let's create
a custom plugin called `Gamble` in `src/plugins/gamble.jl` that only generates a file if
you get lucky enough:

```julia
@auto_hash_equals struct Gamble <: CustomPlugin
    gitignore:Vector{AbstractString}
    src::AbstractString
    success::Bool

    function Gamble(config_file::AbstractString)
        if !isfile(config_file)
            throw(ArgumentError("File $(abspath(config_file)) does not exist"))
        end
        success = rand() > 0.8
        println(success ? "Congratulations!" : "Maybe next time.")
        new([], config_file, success)
    end
end

function badges(plugin: Gamble, user::AbstractString, pkg_name::AbstractString)
    if plugin.success
        return ["[![You won!](https://i.imgur.com/poker-chip)](https://pokerstars.net)"]
    else
        return String[]
    end
end

function gen_plugin(plugin::Gamble, template::Template, pkg_name::AbstractString)
    if plugin.success
        text = substitute(readstring(plugin.src), template, pkg_name)
        gen_file(joinpath(t.temp_dir, ".gambler.yml"), text)
        return [".gambler.yml"]
    else
        return String[]
    end
end
```

With that, we've got everything we need. Note that this plugin still has a `gitignore`
attribute; it's required for all plugins. Let's look at the extra methods we implemented:

#### `gen_plugin`

We read the text from the plugin's source file, and then we run it through the `substitute`
function (more on that [later](#template-substitution)).

Next, we use `gen_file` to write the text, with substitutions applied, to the destination
file in `t.temp_dir`. Generating our repository in a temp directory means we're not stuck
with leftovers in the case of an error.

This function returns an array of all the root-level files or directories
that were created. If both `foo/bar` and `foo/baz` were created, we only need
to return `["foo/"]`.

#### `badges`

This function returns an array of Markdown-formatted badges to be displayed on
the package README. You can find badges and Markdown strings for just about
everything on [Shields.io](https://shields.io).

This will do the trick, but if we want our badge to appear at a specific
position in the README, we need to edit `BADGE_ORDER` in
[`src/PkgTemplates.jl`(https://github.com/invenia/PkgTemplates.jl/blob/master/src/PkgTemplates.jl).
Say we want our badge to appear before all others, we'll add `Gamble` to the
beginning of the array.

That's all there is to it! We've just created a nifty custom plugin.

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
