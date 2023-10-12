"""
    CodeOwners <: Plugin
    CodeOwners(; owners)

A plugin which created GitLab/GitHub compatible CODEOWNERS files.
owners should be a vector of patterns mapped to a vector of owner names.
For example:
`owners=["*"=>["@invenia"], "README.md"=>["@documentation","@oxinabox]]`
assigns general ownership over all files to the invenia group,
but assigns ownership of the readme to the documentation group and to the user oxinabox.

By default, it creates an empty CODEOWNERS file.
"""
@plugin struct CodeOwners <: Plugin
    owners::Vector{Pair{String,Vector{String}}} = Vector{Pair{String,Vector{String}}}()
end

PkgTemplates.destination(::CodeOwners) = "CODEOWNERS"

function render_plugin(p::CodeOwners)
    join((pattern * " " * join(subowners, " ") for (pattern, subowners) in p.owners), "\n")
end

function PkgTemplates.hook(p::CodeOwners, ::Template, pkg_dir::AbstractString)
    path = joinpath(pkg_dir, destination(p))
    text = render_plugin(p)
    PkgTemplates.gen_file(path, text)
end

function PkgTemplates.validate(p::CodeOwners, ::Template)
    for (pattern, subowners) in p.owners
        contains(pattern, r"\s") && throw(ArgumentError(("Pattern ($pattern) must not contain whitespace")))
        for subowner in subowners
            contains(subowner, r"\s") && throw(ArgumentError("Owner name ($subowner) must not contain whitespace"))
            '@' ∈ subowner || throw(ArgumentError("Owner name ($subowner) must be `@user` or `email@domain.com`"))
        end
    end
end
