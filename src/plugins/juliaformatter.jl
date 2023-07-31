"""
    JuliaFormatter(;
        file="$(contractuser(default_file(".JuliaFormatter.toml")))",
        style=""
    )

Create a `.JuliaFormatter.toml` file, used by [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) and the Julia VSCode extension to configure automatic code formatting.

This file can be entirely customized by the user, see the [JuliaFormatter.jl docs](https://domluna.github.io/JuliaFormatter.jl/stable/).

## Keyword Arguments
- `file::String`: Template file for `.JuliaFormatter.toml`.
- `style::Union{Nothing,String}`: Style name, defaults to the empty string `""` for no style but can also be one of `("sciml", "blue", "yas")` for a preconfigured style.
"""
@plugin struct JuliaFormatter <: FilePlugin
    file::String = default_file(".JuliaFormatter.toml")
    style::String = ""
end

source(p::JuliaFormatter) = p.file
destination(::JuliaFormatter) = ".JuliaFormatter.toml"

function view(p::JuliaFormatter, t::Template, pkg::AbstractString)
    d = Dict{String,String}()
    if p.style == ""
        d["STYLE"] = ""
    elseif p.style in ("blue", "sciml", "yas")
        d["STYLE"] = """style = \"$(p.style)\""""
    else
        throw(ArgumentError("Formatting style not recognized"))
    end
    return d
end
