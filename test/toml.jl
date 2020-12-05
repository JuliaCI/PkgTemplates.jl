using Test
using TOML
using PkgTemplates
using Configurations

t = Template(;user="me")
@test from_dict(Template, to_dict(t)) == t
@test toml(t) == """
user = "me"
authors = ["Roger-luo <rogerluo.rl18@gmail.com> and contributors"]
dir = "~/.julia/dev"
host = "github.com"
julia = "1.0.0"
"""

t = Template(;user="me", plugins=[!Git])
src = """
user = "me"
authors = ["Roger-luo <rogerluo.rl18@gmail.com> and contributors"]
dir = "~/.julia/dev"
host = "github.com"
julia = "1.0.0"

[CompatHelper]
[License]
[ProjectFile]
[Readme]
[SrcDir]
[TagBot]
[Tests]
"""
d = TOML.parse(src)

@test from_dict(Template, d) == t

# https://github.com/JuliaLang/TOML.jl/issues/13
@test_broken toml(t) == src
