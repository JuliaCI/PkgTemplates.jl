"""
    Citation(;
        file="$(contractuser(default_file("CITATION.bib")))",
        readme=false,
    ) -> Citation

Creates a `CITATION.bib` file for citing package repositories.

## Keyword Arguments
- `file::AbstractString`: Template file for `CITATION.bib`.
- `readme::Bool`: Whether or not to include a section about citing in the README.
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
