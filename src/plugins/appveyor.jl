"""
    AppVeyor(; config_file::AbstractString="") -> AppVeyor

Add AppVeyor to a template's plugins to add AppVeyor CI support.

# Keyword Arguments
* `config_file::Union{AbstractString, Void}`: Path to a custom `.appveyor.yml`.
  If `nothing` is supplied, then no file will be generated.
"""
struct AppVeyor <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function AppVeyor(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "appveyor.yml")
            end
            if !isfile(abspath(config_file))
                throw(ArgumentError("File $config_file does not exist"))
            end
        end
        new(AbstractString[], config_file)
    end
end

function ==(a::AppVeyor, b::AppVeyor)
    return a.gitignore_files == b.gitignore_files &&
        a.config_file == b.config_file
end

"""
    badges(plugin::AppVeyor, pkg_name::AbstractString, t::Template) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `plugin::AppVeyor`: Plugin whose badges we are generating.
* `t::Template`: Template configuration options.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(plugin::AppVeyor, t::Template, pkg_name::AbstractString)
    user = strip(URI(t.remote_prefix).path, '/')
    return [
        "[![Build status](https://ci.appveyor.com/api/projects/status/github/$user/$pkg_name.jl?svg=true)](https://ci.appveyor.com/project/$user/$pkg_name-jl)"
    ]
end

"""
    gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a .appveyor.yml.

# Arguments
* `plugin::AppVeyor`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files.
"""
function gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    pkg_dir = joinpath(template.path, pkg_name)
    gen_file(joinpath(pkg_dir, ".appveyor.yml"), text)
    return [".appveyor.yml"]
end
