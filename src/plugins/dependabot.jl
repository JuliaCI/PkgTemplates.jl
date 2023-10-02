"""
    Dependabot(; file="$(contractuser(default_file("github", "dependabot.yml")))")

Setups Dependabot to create PRs whenever GitHub actions can be updated.
This is very similar to [`CompatHelper`](@ref), which performs the same task
for Julia package dependencies.

!!! note "Only for GitHub actions"
    Currently, this plugin is configured to setup Dependabot only for the
    GitHub actions package ecosystem. For example, it will create PRs whenever
    GitHub actions such as `uses: actions/checkout@v3` can be updated to
    `uses: actions/checkout@v4`. If you want to configure Dependabot to update
    other package ecosystems, please modify the resulting file yourself.

## Keyword Arguments
- `file::AbstractString`: Template file for `dependabot.yml`.
"""
@plugin struct Dependabot <: FilePlugin
    file::String = default_file("github", "dependabot.yml")
end

source(p::Dependabot) = p.file
destination(::Dependabot) = joinpath(".github", "dependabot.yml")
