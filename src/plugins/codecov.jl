"""
    CodeCov(; config_file::AbstractString="") -> CodeCov

Add CodeCov to a template's plugins to enable CodeCov coverage reports.

# Keyword Arguments:
* `config_file::AbstractString`: Path to a custom `.codecov.yml`.
  If `nothing` is supplied, then no file will be generated.
"""
@auto_hash_equals struct CodeCov <: Plugin
    gitignore_files::Vector{AbstractString}
    config_file::Union{AbstractString, Void}

    function CodeCov(; config_file::Union{AbstractString, Void}="")
        if config_file != nothing
            if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "codecov.yml")
            end
            if !isfile(abspath(config_file))
                throw(ArgumentError("File $config_file does not exist"))
            end
        end
        new(["*.jl.cov", "*.jl.*.cov", "*.jl.mem"], config_file)
    end
end

"""
    badges(\_::CodeCov, user::AbstractString, pkg_name::AbstractString) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::CodeCov`: Plugin whose badges we are generating.
* `user::AbstractString`: GitHub username of the package creator.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::CodeCov, user::AbstractString, pkg_name::AbstractString)
    return [
        "[![CodeCov](https://codecov.io/gh/$user/$pkg_name.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$user/$pkg_name.jl)"
    ]
end

"""
    gen_plugin(plugin::CodeCov, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a .codecov.yml.

# Arguments
* `plugin::CodeCov`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated file/directory names.
"""
function gen_plugin(plugin::CodeCov, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    gen_file(joinpath(template.temp_dir, pkg_name, ".codecov.yml"), text)
    return [".codecov.yml"]
end
