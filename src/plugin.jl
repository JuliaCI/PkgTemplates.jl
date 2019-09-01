const DEFAULTS_DIR = normpath(joinpath(@__DIR__, "..", "defaults"))

badge_order() = [
    Documenter{GitLabCI},
    Documenter{TravisCI},
    GitLabCI,
    TravisCI,
    AppVeyor,
    CirrusCI,
    Codecov,
    Coveralls,
]

"""
A simple plugin that, in general, manages a single file.
For example, most CI services reply on one configuration file.

TODO: Dev guide.
"""
abstract type BasicPlugin <: Plugin end

# Compute the path to a default template file in this repository.
default_file(paths::AbstractString...) = joinpath(DEFAULTS_DIR, paths...)

"""
    view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

Return the string replacements to be made for this plugin.
`pkg` is the name of the package being generated.
"""
view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    user_view(::Plugin, ::Template, pkg::AbstractString) -> Dict{String, Any}

The same as [`view`](@ref), but for use only by package *users* for extension.
TODO better explanation
"""
user_view(::Plugin, ::Template, ::AbstractString) = Dict{String, Any}()

"""
    tags(::Plugin) -> Tuple{String, String}

Return the tags used for Mustache templating.
"""
tags(::Plugin) = ("{{", "}}")

"""
    gitignore(::Plugin) -> Vector{String}

Return patterns that should be added to `.gitignore`.
"""
gitignore(::Plugin) = String[]

"""
    badges(::Plugin) -> Union{Badge, Vector{Badge}}

Return a list of [`Badge`](@ref)s, or just one, to be added to `README.md`.
"""
badges(::Plugin) = Badge[]

"""
    source(::BasicPlugin) -> Union{String, Nothing}

Return the path to a plugin's configuration file template, or `nothing` to indicate no file.
"""
source(::BasicPlugin) = nothing

"""
    destination(::BasicPlugin) -> String

Return the destination, relative to the package root, of a plugin's configuration file.
"""
function destination end

"""
    Badge(hover::AbstractString, image::AbstractString, link::AbstractString) -> Badge

Container for Markdown badge data.
Each argument can contain placeholders.

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
    # TODO template rendering code
    return render_file(source(p), combined_view(p, t, pkg), tags(p))
end

function combined_view(p::Plugin, t::Template, pkg::AbstractString)
    return merge(view(p, t, pkg), user_view(p, t, pkg))
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

# Render text from a file.
function render_file(file::AbstractString, view::Dict{<:AbstractString}, tags)
    render_text(read(file, String), view, tags)
end

# Render text using Mustache's templating system. HTML escaping is disabled.
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
