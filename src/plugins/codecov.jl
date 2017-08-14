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
    badges(\_::CodeCov, pkg_name::AbstractString, t::Template) -> Vector{String}

Generate Markdown badges for the current package.

# Arguments
* `_::CodeCov`: plugin whose badges we are generating.
* `t::Template`: Template configuration options.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of Markdown badges.
"""
function badges(_::CodeCov, t::Template, pkg_name::AbstractString)
    user = strip(URI(t.remote_prefix).path, '/')
    return [
        "[![codecov](https://codecov.io/gh/$user/$pkg_name.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/$user/$pkg_name.jl)"
    ]
end

"""
    gen_plugin(plugin::CodeCov, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a .codecov.yml.

# Arguments
* `plugin::CodeCov`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files.
"""
function gen_plugin(plugin::CodeCov, template::Template, pkg_name::AbstractString)
    if plugin.config_file == nothing
        return String[]
    end
    text = substitute(readstring(plugin.config_file), pkg_name, template)
    pkg_dir = joinpath(template.path, pkg_name)
    gen_file(joinpath(pkg_dir, ".codecov.yml"), text)
    return [".codecov.yml"]
end
