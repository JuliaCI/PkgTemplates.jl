"""
    Dependabot(; file="$(contractuser(default_file("github", "dependabot.yml")))")

Sets up Dependabot to create PRs whenever GitHub Actions or Julia package dependencies
can be updated. Monitors the root `/`, `/docs`, and `/test` directories for Julia dependencies.

As of December 2025, [Dependabot supports Julia](https://github.blog/changelog/2025-12-16-dependabot-version-updates-now-support-julia/)
and is the recommended approach for keeping package dependencies up to date.
This replaces the functionality previously provided by [`CompatHelper`](@ref).

!!! note "Only for GitHub actions"
    Currently, this plugin is configured to setup Dependabot only for the
    GitHub actions package ecosystem. For example, it will create PRs whenever
    GitHub actions such as `uses: actions/checkout@v5` can be updated to
    `uses: actions/checkout@v6`. If you want to configure Dependabot to update
    other package ecosystems, please modify the resulting file yourself.

## Keyword Arguments
- `file::AbstractString`: Template file for `dependabot.yml`.
"""
@plugin struct Dependabot <: FilePlugin
    file::String = default_file("github", "dependabot.yml")
end

source(p::Dependabot) = p.file
destination(::Dependabot) = joinpath(".github", "dependabot.yml")
