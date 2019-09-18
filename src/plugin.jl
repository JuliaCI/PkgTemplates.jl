const DEFAULTS_DIR = normpath(joinpath(@__DIR__, "..", "defaults"))

"""
A simple plugin that, in general, creates a single file.
"""
abstract type BasicPlugin <: Plugin end

"""
    default_file(paths::AbstractString...) -> String

Return a path relative to the default template file directory (`$(contractuser(DEFAULTS_DIR))`).
"""
default_file(paths::AbstractString...) = joinpath(DEFAULTS_DIR, paths...)

"""
    view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

Return the view to be passed to the text templating engine for this plugin.
`pkg` is the name of the package being generated.

For [`BasicPlugin`](@ref)s, this is used for both the plugin badges (see [`badges`](@ref)) and the template file (see [`source`](@ref)).
For other [`Plugin`](@ref)s, it is used only for badges, but you can always call it yourself as part of your [`gen_plugin`](@ref) implementation.

By default, an empty `Dict` is returned.
"""
view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    user_view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

The same as [`view`](@ref), but for use by package *users* for extension.

Values returned by this function will override those from [`view`](@ref) when the keys are the same.
"""
user_view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    combined_view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

This function combines [`view`](@ref) and [`user_view`](@ref) for use in text templating.
If you're doing manual file creation or text templating (i.e. writing [`Plugin`](@ref)s that are not [`BasicPlugin`](@ref)s), then you should use this function rather than either of the former two.

!!! note
    Do not implement this function yourself!
    If you're implementing a plugin, you should implement [`view`](@ref).
    If you're customizing a plugin as a user, you should implement [`user_view`](@ref).
"""
function combined_view(p::Plugin, t::Template, pkg::AbstractString)
    return merge(view(p, t, pkg), user_view(p, t, pkg))
end

"""
    tags(::Plugin) -> Tuple{String, String}

Return the delimiters used for text templating.
See the [`Citation`](@ref) plugin for a rare case where changing the tags is necessary.

By default, the tags are `"{{"` and `"}}"`.
"""
tags(::Plugin) = "{{", "}}"

"""
    gitignore(::Plugin) -> Vector{String}

Return patterns that should be added to `.gitignore`.
These are used by the [`Gitignore`](@ref) plugin.

By default, an empty list is returned.
"""
gitignore(::Plugin) = String[]

"""
    badges(::Plugin) -> Union{Badge, Vector{Badge}}

Return a list of [`Badge`](@ref)s, or just one, to be added to `README.md`.
These are used by the [`Readme`](@ref) plugin to add badges to the README.

By default, an empty list is returned.
"""
badges(::Plugin) = Badge[]

"""
    source(::BasicPlugin) -> Union{String, Nothing}

Return the path to a plugin's template file, or `nothing` to indicate no file.

By default, `nothing` is returned.
"""
source(::BasicPlugin) = nothing

"""
    destination(::BasicPlugin) -> String

Return the destination, relative to the package root, of a plugin's configuration file.

This function **must** be implemented.
"""
function destination end

"""
    Badge(hover::AbstractString, image::AbstractString, link::AbstractString)

Container for Markdown badge data.
Each argument can contain placeholders (which will be filled in with values from [`combined_view`](@ref)).

## Arguments
* `hover::AbstractString`: Text to appear when the mouse is hovered over the badge.
* `image::AbstractString`: URL to the image to display.
* `link::AbstractString`: URL to go to upon clicking the badge.
"""
struct Badge
    hover::String
    image::String
    link::String
end

Base.string(b::Badge) = "[![$(b.hover)]($(b.image))]($(b.link))"

# Format a plugin's badges as a list of strings, with all substitutions applied.
function badges(p::Plugin, t::Template, pkg::AbstractString)
    bs = badges(p)
    bs isa Vector || (bs = [bs])
    return map(b -> render_text(string(b), combined_view(p, t, pkg)), bs)
end

"""
    gen_plugin(::Plugin, ::Template, pkg::AbstractString)

Perform any work associated with a plugin.
`pkg` is the name of the package being generated.

For [`Plugin`](@ref)s that are not [`BasicPlugin`](@ref)s, this is the only function that really needs to be implemented.
If you want your plugin to do anything at all during package generation, you should implement it here.

You should **not** implement this function for `BasicPlugin`s.
"""
gen_plugin(::Plugin, ::Template, ::AbstractString) = nothing

function gen_plugin(p::BasicPlugin, t::Template, pkg_dir::AbstractString)
    source(p) === nothing && return
    pkg = basename(pkg_dir)
    path = joinpath(pkg_dir, destination(p))
    text = render_plugin(p, t, pkg)
    gen_file(path, text)
end

function render_plugin(p::BasicPlugin, t::Template, pkg::AbstractString)
    return render_file(source(p), combined_view(p, t, pkg), tags(p))
end

"""
    gen_file(file::AbstractString, text::AbstractString)

Create a new file containing some given text.
Trailing whitespace is removed, and the file will end with a newline.
"""
function gen_file(file::AbstractString, text::AbstractString)
    mkpath(dirname(file))
    text = strip(join(map(rstrip, split(text, "\n")), "\n")) * "\n"
    write(file, text)
end

"""
    render_file(file::AbstractString view::Dict{<:AbstractString}, tags) -> String

Render a template file with the data in `view`.
`tags` should be a tuple of two strings, which are the opening and closing delimiters, or `nothing` to use the default delimiters.
"""
function render_file(file::AbstractString, view::Dict{<:AbstractString}, tags)
    render_text(read(file, String), view, tags)
end

"""
    render_text(text::AbstractString, view::Dict{<:AbstractString}, tags=nothing) -> String

Render some text with the data in `view`.
`tags` should be a tuple of two strings, which are the opening and closing delimiters, or `nothing` to use the default delimiters.
"""
function render_text(text::AbstractString, view::Dict{<:AbstractString}, tags=nothing)
    saved = copy(entityMap)
    empty!(entityMap)
    return try
        if tags === nothing
            render(text, view)
        else
            render(text, view; tags=tags)
        end
    finally
        append!(entityMap, saved)
    end
end

include(joinpath("plugins", "defaults.jl"))
include(joinpath("plugins", "coverage.jl"))
include(joinpath("plugins", "ci.jl"))
include(joinpath("plugins", "citation.jl"))
include(joinpath("plugins", "documenter.jl"))
