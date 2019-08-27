"""
    Citation(; readme_section::Bool=false) -> Citation

Add `Citation` to a [`Template`](@ref)'s plugin list to generate a `CITATION.bib` file.
If `readme` is set, then `README.md` will contain a section about citing.
"""
@with_kw struct Citation <: BasicPlugin
    file::String = default_file("CITATION.bib")
    readme::Bool = false
end

tags(::Citation) = "<<", ">>"

source(p::Citation) = p.file
destination(::Citation) = "CITATION.bib"

view(::Citation, t::Template, pkg::AbstractString) = Dict(
    "AUTHORS" => join(t.authors, ", "),
    "MONTH" => month(today()),
    "PKG" => pkg,
    "URL" => "https://$(t.host)/$(t.user)/$pkg.jl",
    "YEAR" => year(today()),
)

function interactive(::Type{Citation})
    readme = prompt_bool("Citation: Add a section to the README", false)
    return Citation(; readme_section=readme)
end
