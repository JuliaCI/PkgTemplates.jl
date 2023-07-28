"""
    JuliaFormatter(;
        file="$(contractuser(default_file(".JuliaFormatter.toml")))",
        style="sciml"
    )

Creates a `.JuliaFormatter.toml` file where the formatting style is specified.

This file is used by [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) and the Julia VSCode extension to configure automatic formatting.
It can be further customized by the user beyond the style name, see the [JuliaFormatter.jl docs](https://domluna.github.io/JuliaFormatter.jl/stable/).

## Keyword Arguments
- `file::String`: Template file for `.JuliaFormatter.toml`.
- `style::String`: Compatible style name (either "sciml", "blue" or "yas")
"""
@plugin struct JuliaFormatter <: FilePlugin
    file::String = default_file(".JuliaFormatter.toml")
    style::String = "sciml"
end

source(p::JuliaFormatter) = p.file
destination(::JuliaFormatter) = ".JuliaFormatter.toml"

view(p::JuliaFormatter, t::Template, pkg::AbstractString) = Dict(
    "STYLE" => p.style,
)
