@info "testing TOML conversion"

t = Template(;user="me", authors = ["Tester <te@st.er> and contributors"])
@test from_dict(Template, to_dict(t)) == t

@test toml(t) == """
user = "me"
authors = ["Tester <te@st.er> and contributors"]
"""

src = """
user = "me"
authors = ["Tester <te@st.er> and contributors"]
dir = "a/b/c"
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

@test from_dict(Template, d) == Template(;user="me",
    authors=["Tester <te@st.er> and contributors"],
    dir=normpath("a/b/c"), plugins=[!Git]
)

# https://github.com/JuliaLang/TOML.jl/issues/13
@test_broken toml(t) == src
