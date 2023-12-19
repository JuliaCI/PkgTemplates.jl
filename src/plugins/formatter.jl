"""
    Formatter(;
        file="$(contractuser(default_file(".JuliaFormatter.toml")))",
        style="nostyle"
    )

Create a `.JuliaFormatter.toml` file, used by [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) and the Julia VSCode extension to configure automatic code formatting.

This file can be entirely customized by the user, see the [JuliaFormatter.jl docs](https://domluna.github.io/JuliaFormatter.jl/stable/).

## Keyword Arguments
- `file::String`: Template file for `.JuliaFormatter.toml`.
- `style::String`: Style name, defaults to `"nostyle"` for an empty style but can also be one of `("sciml", "blue", "yas")` for a fully preconfigured style.
"""
@plugin struct Formatter <: FilePlugin
    file::String = default_file(".JuliaFormatter.toml")
    style::String = "nostyle"
end

function validate(p::Formatter, t::Template)
    if p.style ∉ ("nostyle", "blue", "sciml", "yas")
        throw(ArgumentError("""JuliaFormatter style must be either "nostyle", "blue", "sciml" or "yas"."""))
    end
end

source(p::Formatter) = p.file
destination(::Formatter) = ".JuliaFormatter.toml"

function view(p::Formatter, t::Template, pkg::AbstractString)
    d = Dict{String,String}()
    if p.style == "nostyle"
        d["STYLE"] = ""
    else
        d["STYLE"] = """style = \"$(p.style)\""""
    end
    return d
end

function prompt(::Type{Formatter}, ::Type{String}, ::Val{:style})
    options = ["nostyle", "blue", "sciml", "yas"]
    menu = RadioMenu(options; pagesize=length(options))
    println("Select a JuliaFormatter style:")
    idx = request(menu)
    return options[idx]
end
