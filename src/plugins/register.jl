"""
    Register(;
        file="$(contractuser(default_file("github", "workflows", "register.yml")))",
        destination="register.yml",
        prompt="Version to register or component to bump",
    )

Add a GitHub Action workflow for registering a package with the general registry via workflow dispatch. See https://github.com/julia-actions/RegisterAction for more information.

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file,
  relative to `.github/workflows`.
- `prompt::AbstractString`: Prompt for workflow dispatch.
"""
@plugin struct CompatHelper <: FilePlugin
    file::String = default_file("github", "workflows", "register.yml")
    destination::String = "register.yml"
    prompt::String = "Version to register or component to bump"
end

source(p::CompatHelper) = p.file
destination(p::CompatHelper) = joinpath(".github", "workflows", p.destination)
tags(::CompatHelper) = "<<", ">>"

view(p::CompatHelper, ::Template, ::AbstractString) = Dict("PROMPT" => p.prompt)
