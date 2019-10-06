const TEMPLATES_DIR = normpath(joinpath(@__DIR__, "..", "templates"))
const DEFAULT_PRIORITY = 1000

"""
A simple plugin that, in general, creates a single file.
"""
abstract type BasicPlugin <: Plugin end

"""
    default_file(paths::AbstractString...) -> String

Return a path relative to the default template file directory
(`$(contractuser(TEMPLATES_DIR))`).
"""
default_file(paths::AbstractString...) = joinpath(TEMPLATES_DIR, paths...)

"""
    view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

Return the view to be passed to the text templating engine for this plugin.
`pkg` is the name of the package being generated.

For [`BasicPlugin`](@ref)s, this is used for both the plugin badges
(see [`badges`](@ref)) and the template file (see [`source`](@ref)).
For other [`Plugin`](@ref)s, it is used only for badges,
but you can always call it yourself as part of your [`hook`](@ref) implementation.

By default, an empty `Dict` is returned.
"""
view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    user_view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

The same as [`view`](@ref), but for use by package *users* for extension.

Values returned by this function will override those from [`view`](@ref)
when the keys are the same.
"""
user_view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    combined_view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

This function combines [`view`](@ref) and [`user_view`](@ref) for use in text templating.
If you're doing manual file creation or text templating (i.e. writing [`Plugin`](@ref)s
that are not [`BasicPlugin`](@ref)s), then you should use this function
rather than either of the former two.

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
    priority(::Plugin, ::Union{typeof(prehook), typeof(hook), typeof(posthook)}) -> Int

Determines the order in which plugins are processed (higher goes first).
The default priority (`DEFAULT_PRIORITY`), is `$DEFAULT_PRIORITY`.

You can implement this function per-stage (by using `::typeof(hook)`, for example),
or for all stages by simply using `::Function`.
"""
priority(::Plugin, ::Function) = DEFAULT_PRIORITY

"""
    gitignore(::Plugin) -> Vector{String}

Return patterns that should be added to `.gitignore`.
These are used by the [`Git`](@ref) plugin.

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
Each argument can contain placeholders,
which will be filled in with values from [`combined_view`](@ref).

## Arguments
- `hover::AbstractString`: Text to appear when the mouse is hovered over the badge.
- `image::AbstractString`: URL to the image to display.
- `link::AbstractString`: URL to go to upon clicking the badge.
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
    validate(::Plugin, ::Template)

Perform any required validation for a [`Plugin`](@ref).

It is preferred to do validation here instead of in [`prehook`](@ref),
because this function is called at [`Template`](@ref) construction time,
whereas the prehook is only run at package generation time.
"""
validate(::Plugin, ::Template) = nothing

"""
    prehook(::Plugin, ::Template, pkg_dir::AbstractString)

Stage 1 of the package generation process (the "before" stage, in general).
At this point, `pkg_dir` is an empty directory that will eventually contain the package,
and neither the [`hook`](@ref)s nor the [`posthook`](@ref)s have run.

!!! note
    `pkg_dir` only stays empty until the first plugin chooses to create a file.
    See also: [`priority`](@ref).
"""
prehook(::Plugin, ::Template, ::AbstractString) = nothing

"""
    hook(::Plugin, ::Template, pkg_dir::AbstractString)

Stage 2 of the package generation pipeline (the "main" stage, in general).
At this point, the [`prehook`](@ref)s have run, but not the [`posthook`](@ref)s.

`pkg_dir` is the directory in which the package is being generated
(so `basename(pkg_dir)` is the package name).

!!! note
    You usually shouldn't implement this function for [`BasicPlugin`](@ref)s.
    If you do, it should probably `invoke` the generic method
    (otherwise, there's not much reason to subtype `BasicPlugin`).
"""
hook(::Plugin, ::Template, ::AbstractString) = nothing

"""
    posthook(::Plugin, ::Template, pkg_dir::AbstractString)

Stage 3 of the package generation pipeline (the "after" stage, in general).
At this point, both the [`prehook`](@ref)s and [`hook`](@ref)s have run.
"""
posthook(::Plugin, ::Template, ::AbstractString) = nothing

function validate(p::T, ::Template) where T <: BasicPlugin
    src = source(p)
    src === nothing && return
    isfile(src) || throw(ArgumentError("$(nameof(T)): The file $src does not exist"))
end

function hook(p::BasicPlugin, t::Template, pkg_dir::AbstractString)
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
`tags` should be a tuple of two strings, which are the opening and closing delimiters,
or `nothing` to use the default delimiters.
"""
function render_file(file::AbstractString, view::Dict{<:AbstractString}, tags)
    return render_text(read(file, String), view, tags)
end

"""
    render_text(text::AbstractString, view::Dict{<:AbstractString}, tags=nothing) -> String

Render some text with the data in `view`.
`tags` should be a tuple of two strings, which are the opening and closing delimiters,
or `nothing` to use the default delimiters.
"""
function render_text(text::AbstractString, view::Dict{<:AbstractString}, tags=nothing)
    return tags === nothing ? render(text, view) : render(text, view; tags=tags)
end

"""
    needs_username(::Plugin) -> Bool

Determine whether or not a plugin needs a Git hosting service username to function correctly.
If you are implementing a plugin that uses the `user` field of a [`Template`](@ref),
you should implement this function and return `true`.
"""
needs_username(::Plugin) = false

include(joinpath("plugins", "project_file.jl"))
include(joinpath("plugins", "src_dir.jl"))
include(joinpath("plugins", "tests.jl"))
include(joinpath("plugins", "readme.jl"))
include(joinpath("plugins", "license.jl"))
include(joinpath("plugins", "git.jl"))
include(joinpath("plugins", "develop.jl"))
include(joinpath("plugins", "coverage.jl"))
include(joinpath("plugins", "ci.jl"))
include(joinpath("plugins", "citation.jl"))
include(joinpath("plugins", "documenter.jl"))
