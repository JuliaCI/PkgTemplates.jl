"""
    Dependabot(; file="$(contractuser(default_file("github", "dependabot.yml")))")

Setups Dependabot to create PRs whenever GitHub actions can be updated.
This is very similar to [`CompatHelper`](@ref), which performs the same task
for Julia package dependencies.

## Keyword Arguments
- `file::AbstractString`: Template file for `dependabot.yml`.
"""
@plugin struct Dependabot <: FilePlugin
    file::String = default_file("github", "dependabot.yml")
end

source(p::Dependabot) = p.file
destination(::Dependabot) = joinpath(".github", "dependabot.yml")
