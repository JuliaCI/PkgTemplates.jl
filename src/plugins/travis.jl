"""
    TravisCI(;config_file::AbstractString="") -> TravisCI

Add TravisCI to a template's plugins to enable Travis CI.

# Keyword Arguments:
* `config_file::AbstractString`: Path to a custom `.travis.yml`.
"""
struct TravisCI <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::AbstractString

    function TravisCI(;config_file::AbstractString="")
        config_file = isempty(config_file) ?
            joinpath(DEFAULTS_DIR, "travis.yml") : config_file
        if !isfile(config_file)
            throw(ArgumentError("File $config_file does not exist"))
        end
        new(AbstractString[], config_file)
    end
end

function ==(a::TravisCI, b::TravisCI)
    return a.gitignore_files == b.gitignore_files &&
        a.config_file == b.config_file
end

"""
    badges(plugin::TravisCI, pkg_name::AbstractString, t::Template) -> String

Return Markdown badges for the current package.

# Arguments
* `plugin::TravisCI`: plugin whose badges we are generating.
* `t::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.
"""
function badges(plugin::TravisCI, t::Template, pkg_name::AbstractString)
    user = strip(URI(t.remote_prefix).path, '/')
    return [
        "[![Build Status](https://travis-ci.org/$user/$pkg_name.jl.svg?branch=master)](https://travis-ci.org/$user/$pkg_name.jl)"
    ]
end

"""
    gen_plugin(plugin::TravisCI, template::Template, pkg_name::AbstractString)

Generate a .travis.yml.

# Arguments
* `plugin::TravisCI`: The plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files ([".travis.yml"]) for git to add.
"""
function gen_plugin(plugin::TravisCI, template::Template, pkg_name::AbstractString)
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    pkg_dir = joinpath(template.path, pkg_name)
    gen_file(joinpath(pkg_dir, ".travis.yml"), text)
    return [".travis.yml"]
end
