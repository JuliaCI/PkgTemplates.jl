"""
    TravisCI(; config_file::AbstractString="") -> TravisCI

Add TravisCI to a template's plugins to add Travis CI support.

# Keyword Arguments:
* `config_file::AbstractString`: Path to a custom `.travis.yml`.
  If `nothing` is supplied, then no file will be generated.
"""
struct TravisCI <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function TravisCI(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "travis.yml")
            end
            if !isfile(abspath(config_file))
                throw(ArgumentError("File $config_file does not exist"))
            end
        end
        new(AbstractString[], config_file)
    end
end

function ==(a::TravisCI, b::TravisCI)
    return a.gitignore_files == b.gitignore_files &&
        a.config_file == b.config_file
end

"""
    badges(plugin::TravisCI, pkg_name::AbstractString, t::Template) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `plugin::TravisCI`: plugin whose badges we are generating.
* `t::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(plugin::TravisCI, t::Template, pkg_name::AbstractString)
    user = strip(URI(t.remote_prefix).path, '/')
    return [
        "[![Build Status](https://travis-ci.org/$user/$pkg_name.jl.svg?branch=master)](https://travis-ci.org/$user/$pkg_name.jl)"
    ]
end

"""
    gen_plugin(plugin::TravisCI, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a .travis.yml.

# Arguments
* `plugin::TravisCI`: The plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files.
"""
function gen_plugin(plugin::TravisCI, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    pkg_dir = joinpath(template.path, pkg_name)
    gen_file(joinpath(pkg_dir, ".travis.yml"), text)
    return [".travis.yml"]
end
