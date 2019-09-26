"""
    Citation(; file="$(contractuser(default_file("CITATION.bib")))", readme=false)

Creates a `CITATION.bib` file for citing package repositories.

## Keyword Arguments
- `file::AbstractString`: Template file for `CITATION.bib`.
- `readme::Bool`: Whether or not to include a section about citing in the README.
"""
@with_defaults struct Citation <: BasicPlugin
    file::String = default_file("CITATION.bib") <- "Path to CITATION.bib template"
    readme::Bool = false <- """Enable "Citing" README section"""
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

needs_username(::Citation) = true
