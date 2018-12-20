"""
Generic plugins are plugins that add any number of patterns to the generated package's
`.gitignore`, and have at most one associated file to generate.

# Attributes
* `gitignore::Vector{AbstractString}`: Array of patterns to be added to the `.gitignore` of
  generated packages that use this plugin.
* `src::Union{AbstractString, Nothing}`: Path to the file that will be copied into the generated
  package repository. If set to `nothing`, no file will be generated. When this defaults
  to an empty string, there should be a default file in `defaults` that will be copied.
  That file's name is usually the same as the plugin's name, except in all lowercase and
  with the `.yml` extension. If this is not the case, an `interactive` method needs to be
  implemented to call `interactive(; file="file.ext")`.
* `dest::AbstractString`: Path to the generated file, relative to the root of the generated
  package repository.
* `badges::Vector{Badge}`: Array of [`Badge`](@ref)s containing information used to
  create Markdown-formatted badges from the plugin. Entries will be run through
  [`substitute`](@ref), so they may contain placeholder values.
* `view::Dict{String, Any}`: Additional substitutions to make in both the plugin's badges
  and its associated file. See [`substitute`](@ref) for details.

# Example
```julia
struct MyPlugin <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Union{AbstractString, Nothing}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}

    function MyPlugin(; config_file::Union{AbstractString, Nothing}="")
        if config_file != nothing
            config_file = if isempty(config_file)
                joinpath(DEFAULTS_DIR, "my-plugin.toml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError(
                    "File \$(abspath(config_file)) does not exist"
                ))
            end
        end
        new(
            ["*.mgp"],
            config_file,
            ".my-plugin.toml",
            [
                Badge(
                    "My Plugin",
                    "https://myplugin.com/badge-{{YEAR}}.png",
                    "https://myplugin.com/{{USER}}/{{PKGNAME}}.jl",
                ),
            ],
            Dict{String, Any}("YEAR" => year(today())),
        )
    end
end

interactive(::Type{MyPlugin}) = interactive(MyPlugin; file="my-plugin.toml")
```

The above plugin ignores files ending with `.mgp`, copies `defaults/my-plugin.toml` by
default, and creates a badge that links to the project on its own site, using the default
substitutions with one addition: `{{YEAR}} => year(today())`. Since the default config
template file doesn't follow the generic naming convention, we added another `interactive`
method to correct the assumed filename.
"""
abstract type GenericPlugin <: Plugin end

function Base.show(io::IO, p::GenericPlugin)
    spc = "  "
    println(io, nameof(typeof(p)), ":")

    cfg = if p.src === nothing
        "None"
    else
        dirname(p.src) == DEFAULTS_DIR ? "Default" : p.src
    end
    println(io, spc, "→ Config file: ", cfg)

    n = length(p.gitignore)
    s = n == 1 ? "" : "s"
    print(io, spc, "→ $n gitignore entrie$s")
    n > 0 && print(io, ": ", join(map(repr, p.gitignore), ", "))
end

"""
Custom plugins are plugins whose behaviour does not follow the [`GenericPlugin`](@ref)
pattern. They can implement [`gen_plugin`](@ref), [`badges`](@ref), and
[`interactive`](@ref) in any way they choose, as long as they conform to the usual type
signature.

# Attributes
* `gitignore::Vector{AbstractString}`: Array of patterns to be added to the `.gitignore` of
  generated packages that use this plugin.

# Example
```julia
struct MyPlugin <: CustomPlugin
    gitignore::Vector{AbstractString}
    lucky::Bool

    MyPlugin() = new([], rand() > 0.8)

    function gen_plugin(p::MyPlugin, t::Template, pkg_name::AbstractString)
        return if p.lucky
            text = substitute("You got lucky with {{PKGNAME}}, {{USER}}!", t)
            gen_file(joinpath(t.dir, pkg_name, ".myplugin.yml"), text)
            [".myplugin.yml"]
        else
            println("Maybe next time.")
            String[]
        end
    end

    function badges(p::MyPlugin, user::AbstractString, pkg_name::AbstractString)
        return if p.lucky
            [
                format(Badge(
                    "You got lucky!",
                    "https://myplugin.com/badge.png",
                    "https://myplugin.com/\$user/\$pkg_name.jl",
                )),
            ]
        else
            String[]
        end
    end
end

interactive(:Type{MyPlugin}) = MyPlugin()
```

This plugin doesn't do much, but it demonstrates how [`gen_plugin`](@ref), [`badges`](@ref)
and [`interactive`](@ref) can be implemented using [`substitute`](@ref),
[`gen_file`](@ref), [`Badge`](@ref), and [`format`](@ref).

# Defining Template Files
Often, the contents of the config file that your plugin generates depends on variables like
the package name, the user's username, etc. Template files (which are stored in `defaults`)
can use [here](https://github.com/jverzani/Mustache.jl)'s syntax to define replacements.
"""
abstract type CustomPlugin <: Plugin end

"""
    Badge(hover::AbstractString, image::AbstractString, link::AbstractString) -> Badge

A `Badge` contains the data necessary to generate a Markdown badge.

# Arguments
* `hover::AbstractString`: Text to appear when the mouse is hovered over the badge.
* `image::AbstractString`: URL to the image to display.
* `link::AbstractString`: URL to go to upon clicking the badge.
"""
struct Badge
    hover::String
    image::String
    link::String
end

"""
    format(b::Badge) -> String

Return `badge`'s data formatted as a Markdown string.
"""
format(b::Badge) = "[![$(b.hover)]($(b.image))]($(b.link))"

"""
    gen_plugin(p::Plugin, t::Template, pkg_name::AbstractString) -> Vector{String}

Generate any files associated with a plugin.

# Arguments
* `p::Plugin`: Plugin whose files are being generated.
* `t::Template`: Template configuration.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
gen_plugin(::Plugin, ::Template, ::AbstractString) = String[]

function gen_plugin(p::GenericPlugin, t::Template, pkg_name::AbstractString)
    if p.src === nothing
        return String[]
    end
    text = substitute(
        read(p.src, String),
        t;
        view=merge(Dict("PKGNAME" => pkg_name), p.view),
    )
    gen_file(joinpath(t.dir, pkg_name, p.dest), text)
    return [p.dest]
end

"""
    badges(p::Plugin, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the plugin.

# Arguments
* `p::Plugin`: Plugin whose badges we are generating.
* `user::AbstractString`: Username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
badges(::Plugin, ::AbstractString, ::AbstractString) = String[]

function badges(p::GenericPlugin, user::AbstractString, pkg_name::AbstractString)
    # Give higher priority to replacements defined in the plugin's view.
    view = merge(Dict("USER" => user, "PKGNAME" => pkg_name), p.view)
    return map(b -> substitute(format(b), view), p.badges)
end

"""
    interactive(T::Type{<:Plugin}; file::Union{AbstractString, Nothing}="") -> Plugin

Interactively create a plugin of type `T`, where `file` is the plugin type's default
config template with a non-standard name (for `MyPlugin`, this is anything but
"myplugin.yml").
"""
function interactive(T::Type{<:GenericPlugin}; file::Union{AbstractString, Nothing}="")
    name = string(nameof(T))
    # By default, we expect the default plugin file template for a plugin called
    # "MyPlugin" to be called "myplugin.yml".
    fn = file != nothing && isempty(file) ? "$(lowercase(name)).yml" : file
    default_config_file = fn == nothing ? fn : joinpath(DEFAULTS_DIR, fn)

    print("$name: Enter the config template filename (\"None\" for no file) ")
    if default_config_file == nothing
        print("[None]: ")
    else
        print("[", replace(default_config_file, homedir() => "~"), "]: ")
    end

    config_file = readline()
    config_file = if uppercase(config_file) == "NONE"
        nothing
    elseif isempty(config_file)
        default_config_file
    else
        config_file
    end

    return T(; config_file=config_file)
end
