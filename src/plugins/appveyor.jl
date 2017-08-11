"""
    AppVeyor(;config_file::AbstractString="") -> AppVeyor

Add AppVeyor to a template's plugins to add AppVeyor support. AppVeyor is compatible with
any remote.

# Arguments:
* `config_file::AbstractString`: Absolute or relative path to a custom `.codecov.yml`.
"""

struct AppVeyor <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::AbstractString

    function AppVeyor(;config_file::AbstractString="")
        config_file = isempty(config_file) ?
            joinpath(DEFAULTS_DIR, "appveyor.yml") : config_file
        if !isfile(abspath(config_file))
            throw(ArgumentError("File $config_file does not exist"))
        end
        new(AbstractString[], config_file)
    end
end

function ==(a::AppVeyor, b::AppVeyor)
    return a.gitignore_files == b.gitignore_files &&
        a.config_file == b.config_file
end

"""
    badges(plugin::AppVeyor, pkg_name::AbstractString, t::Template) -> String

Return Markdown badges for the current package.

# Arguments
* `plugin::AppVeyor`: plugin whose badges we are generating.
* `t::Template`: Template configuration options.
* `pkg_name::AbstractString`: Name of the package.
"""
function badges(plugin::AppVeyor, t::Template, pkg_name::AbstractString)
    user = strip(URI(t.remote_prefix).path, '/')
    return [
        "[![Build status](https://ci.appveyor.com/api/projects/status/github/$user/$pkg_name.jl?svg=true)](https://ci.appveyor.com/project/$user/$pkg_name-jl)"
    ]
end

"""
    gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString)

Generate a .appveyor.yml.

# Arguments
* `plugin::AppVeyor`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files ([".appveyor.yml"]) for git to add.
"""
function gen_plugin(plugin::AppVeyor, template::Template, pkg_name::AbstractString)
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    pkg_dir = joinpath(template.path, pkg_name)
    gen_file(joinpath(pkg_dir, ".appveyor.yml"), text)
    return [".appveyor.yml"]
end
