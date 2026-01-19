"""
    Dependabot(; file="$(contractuser(default_file("github", "dependabot.yml")))")

Setups Dependabot to create PRs whenever Julia packages (`[compat]` entries) or GitHub Actions can be updated.

!!! note "Only for Julia packages and GitHub Actions"
    Currently, this plugin is configured to setup Dependabot only for the
    Julia and GitHub Actions package ecosystems. For example, it will create PRs
    whenever a Julia `[compat]` entry `Foo = "1"` can be updated to `Foo = "1, 2"`,
    and whenever GitHub actions such as `uses: actions/checkout@v5` can be updated to
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
