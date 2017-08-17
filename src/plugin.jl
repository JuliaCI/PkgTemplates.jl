abstract type GenericPlugin <: Plugin end
abstract type CustomPlugin <: Plugin end

"""
    badges(\_::Plugin, user::AbstractString, pkg_name::AbstractString)

Generate Markdown badges for the current package.

# Arguments
* `plugin::Plugin`: Plugin whose badges we are generating.
* `user::AbstractString`: Username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
badges(plugin::Plugin, user::AbstractString, pkg_name::AbstractString) = String[]

function badges(plugin::GenericPlugin, user::AbstractString, pkg_name::AbstractString)
    return substitute.(
        plugin.badges,
        plugin,
        pkg_name;
        view=Dict{String, Any}("USER" => user)
    )
end

"""
    gen_plugin(plugin::Plugin, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate any files associated with a plugin.

# Arguments
* `plugin::Plugin`: Plugin whose files are being generated.
* `template::Template`: Template configuration.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
gen_plugin(plugin::Plugin, template::Template, pkg_name::AbstractString) = String[]

function gen_plugin(plugin::GenericPlugin, template::Template, pkg_name::AbstractString)
    try
        text = substitute(
            readstring(get(plugin.src)),
            template,
            pkg_name;
            view=plugin.view,
        )
        gen_file(joinpath(template.temp_dir, pkg_name, plugin.dest), text)
        return [plugin.dest]
    catch
        return String[]
    end
end
