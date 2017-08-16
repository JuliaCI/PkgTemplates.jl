"""
    AppVeyor(; config_file::AbstractString="") -> AppVeyor

Add AppVeyor to a template's plugins to add AppVeyor CI support.

# Keyword Arguments
* `config_file::Union{AbstractString, Void}`: Path to a custom `.appveyor.yml`.
  If `nothing` is supplied, then no file will be generated.
"""
@auto_hash_equals struct AppVeyor <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function AppVeyor(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "appveyor.yml")
            end
            if !isfile(config_file)
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        new(AbstractString[], config_file)
    end
end

"""
    badges(\_::AppVeyor, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::AppVeyor`: Plugin whose badges we are generating.
* `user::AbstractString`: GitHub username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::AppVeyor, user::AbstractString, pkg_name::AbstractString)
    return [
        "[![Build Status](https://ci.appveyor.com/api/projects/status/github/$user/$pkg_name.jl?svg=true)](https://ci.appveyor.com/project/$user/$pkg_name-jl)"
    ]
end

"""
    gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a .appveyor.yml.

# Arguments
* `plugin::AppVeyor`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
function gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    gen_file(joinpath(template.temp_dir, pkg_name, ".appveyor.yml"), text)
    return [".appveyor.yml"]
end
