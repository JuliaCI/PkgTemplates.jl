"""
    RegisterAction(;
        file="$(contractuser(default_file("github", "workflows", "Register.yml")))",
        destination="Register.yml",
        prompt="Version to register or component to bump",
    )

Add a GitHub Actions workflow for registering a package with the General registry via workflow dispatch.
See [here](https://github.com/julia-actions/RegisterAction) for more information.

## Keyword Arguments
- `file::AbstractString`: Template file for the workflow file.
- `destination::AbstractString`: Destination of the workflow file,
  relative to `.github/workflows`.
- `prompt::AbstractString`: Prompt for workflow dispatch.
"""
@plugin struct RegisterAction <: FilePlugin
    file::String = default_file("github", "workflows", "Register.yml")
    destination::String = "Register.yml"
    prompt::String = "Version to register or component to bump"
end

source(p::RegisterAction) = p.file
destination(p::RegisterAction) = joinpath(".github", "workflows", p.destination)
tags(::RegisterAction) = "<<", ">>"

view(p::RegisterAction, ::Template, ::AbstractString) = Dict("PROMPT" => p.prompt)
