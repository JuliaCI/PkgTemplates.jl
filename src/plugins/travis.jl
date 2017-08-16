"""
    TravisCI(; config_file::Union{AbstractString, Void}="") -> TravisCI

Add TravisCI to a template's plugins to add Travis CI support.

# Keyword Arguments:
* `config_file::Union{AbstractString, Void}=""`: Path to a custom `.travis.yml`.
  If `nothing` is supplied, then no file will be generated.
"""
@auto_hash_equals struct TravisCI <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function TravisCI(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "travis.yml")
            end
            if !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(AbstractString[], config_file)
    end
end

"""
    badges(\_::TravisCI, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::TravisCI`: plugin whose badges we are generating.
* `user::AbstractString`: GitHub username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::TravisCI, user::AbstractString, pkg_name::AbstractString)
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

Returns an array of generated file/directory names.
"""
function gen_plugin(plugin::TravisCI, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    gen_file(joinpath(template.temp_dir, pkg_name, ".travis.yml"), text)
    return [".travis.yml"]
end
