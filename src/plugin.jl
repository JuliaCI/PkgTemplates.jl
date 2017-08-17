"""
Generic plugins are plugins that add any number of patterns to the generated package's
`.gitignore`, and have at most one associated file to generate.

# Attributes
* `gitignore::Vector{AbstractString}`: Array of patterns to be added to the `.gitignore` of
  generated packages that use this plugin.
* `src::Nullable{AbstractString}`: Path to the file that will be copied into the generated
  package repository. If set to `nothing`, no file will be generated. When this defaults
  to an empty string, there should be a default file in `defaults` that will be copied.
* `dest::AbstractString`: Path to the generated file, relative to the root of the generated
  package repository.
* `badges::Vector{Vector{AbstractString}}`: Array of arrays containing information to
  create a Markdown-formatted badge from the plugin. Each entry is of the form
  `[hover_text, image_url, link_url]`. Entries will be run through [`substitute`](@ref),
  so they may contain placeholder values.
* `view::Dict{String, Any}`: Additional substitutions to make in both the plugin's badges
  and its associated file. See [`substitute`](@ref) for details.

# Example
```julia
@auto_hash_equals struct MyPlugin <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Nullable{AbstractString}
    dest::AbstractString
    badges::Vector{Vector{AbstractString}}
    view::Dict{String, Any}

    function MyPlugin(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "myplugin.yml")
            elseif !isfile(config_file)
                throw(ArgumentError(
                    "File \$(abspath(config_file)) does not exist"
                ))
            end
        end
        new(
            ["*.mgp"],
            config_file,
            ".mypugin.yml",
            [
                [
                    "My Plugin",
                    "https://myplugin.com/badge-{{YEAR}}.png",
                    "https://myplugin.com/{{USER}}/{{PKGNAME}}.jl",
                ],
            ],
            Dict{String, Any}("YEAR" => Dates.year(Dates.now())),
        )
    end
end
```

The above plugin ignores files ending with `.mgp`, copies `defaults/myplugin.yml` by
default, and creates a badge that links to the project on its own site, using the default
substitutions with one addition: `{{YEAR}} => Dates.year(Dates.now())`.
"""
abstract type GenericPlugin <: Plugin end

"""
Custom plugins are plugins whose behaviour does not follow the [`GenericPlugin`](@ref)
pattern. They can implement [`gen_plugin`](@ref) and [`badges`](@ref) in any way they
choose.

# Attributes
* `gitignore::Vector{AbstractString}`: Array of patterns to be added to the `.gitignore` of
  generated packages that use this plugin.

# Example

```julia
@auto_hash_equals struct MyPlugin <: CustomPlugin
    gitignore::Vector{AbstractString}
    lucky::Bool

    MyPlugin() = new([], rand() > 0.8)

    function gen_plugin(
        plugin::MyPlugin,
        template::Template,
        pkg_name::AbstractString
    )
        if plugin.lucky
            text = substitute(
                "You got lucky with {{PKGNAME}}, {{USER}}!"),
                template,
            )
            gen_file(joinpath(template.temp_dir, ".myplugin.yml"), text)
        else
            println("Maybe next time.")
        end
    end

    function badges(
        plugin::MyPlugin,
        user::AbstractString,
        pkg_name::AbstractString,
    )
        if plugin.lucky
            return [
                badge(
                    "You got lucky!",
                    "https://myplugin.com/badge.png",
                    "https://myplugin.com/\$user/\$pkg_name.jl",
                ),
            ]
        else
            return String[]
        end
    end
end
```

This plugin doesn't do much, but it demonstrates how [`gen_plugin`](@ref) and
[`badges`](@ref) can be implemented using [`substitute`](@ref), [`gen_file`](@ref),
and [`badge`](@ref).
"""
abstract type CustomPlugin <: Plugin end

"""
    gen_plugin(plugin::Plugin, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate any files associated with a plugin.

# Arguments
* `plugin::Plugin`: Plugin whose files are being generated.
* `template::Template`: Template configuration.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
gen_plugin(plugin::Plugin, template::Template, pkg_name::AbstractString) = String[]

function gen_plugin(plugin::GenericPlugin, template::Template, pkg_name::AbstractString)
    src = try
        get(plugin.src)
    catch
        return String[]
    end
    text = substitute(
        readstring(src),
        template;
        view=merge(Dict("PKGNAME" => pkg_name), plugin.view),
    )
    gen_file(joinpath(template.temp_dir, pkg_name, plugin.dest), text)
    return [plugin.dest]
end

"""
    badges(plugin::Plugin, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the plugin.

# Arguments
* `plugin::Plugin`: Plugin whose badges we are generating.
* `user::AbstractString`: Username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
badges(plugin::Plugin, user::AbstractString, pkg_name::AbstractString) = String[]

function badges(plugin::GenericPlugin, user::AbstractString, pkg_name::AbstractString)
    # Give higher priority to replacements defined in the plugin's view.
    view = merge(Dict("USER" => user, "PKGNAME" => pkg_name), plugin.view)
    return [badge([substitute(part, view) for part in b]...) for b in plugin.badges]
end

"""
    badge(hover::AbstractString, image::AbstractString, image::AbstractString) -> String

Format a single Markdown badge.

# Arguments
* `hover::AbstractString`: Text to appear when the mouse is hovered over the badge.
* `image::AbstractString`: URL to the image to display.
* `link::AbstractString`: URL to go to upon clicking the badge.
"""
function badge(hover::AbstractString, image::AbstractString, link::AbstractString)
    return "[![$hover]($image)]($link)"
end
