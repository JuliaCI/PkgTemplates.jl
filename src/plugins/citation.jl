"""
    Citation(; readme_section::Bool=false)

Add `Citation` to a template's plugins to add a `CITATION.bib` file to
generated repositories, and an appropriate section in the README.

# Keyword Arguments:
* `readme_section::Bool=false`: whether to add a section in the readme pointing to `CITATION.bib`.
"""
struct Citation <: GenericPlugin
    gitignore::Vector{AbstractString}
    src::Union{String, Nothing}
    dest::AbstractString
    badges::Vector{Badge}
    view::Dict{String, Any}
    readme_section::Bool
    function Citation(; readme_section::Bool=false)
        new(
            [],
            nothing,
            "CITATION.bib",
            [],
            Dict{String, Any}(),
            readme_section,
        )
    end
end

interactive(::Type{Citation}) = interactive(Citation; readme_section=false)

function gen_plugin(p::Citation, t::Template, pkg_name::AbstractString)
    pkg_dir = joinpath(t.dir, pkg_name)
    text = """
           @misc{$pkg_name.jl,
           \tauthor  = {$(t.authors)},
           \ttitle   = {{$(pkg_name).jl}},
           \turl     = {https://$(t.host)/$(t.user)/$(pkg_name).jl},
           \tversion = {v0.1.0},
           \tyear    = {$(year(today()))},
           \tmonth   = {$(month(today()))}
           }
           """
    gen_file(joinpath(pkg_dir, "CITATION.bib"), text)
    return ["CITATION.bib"]
end
