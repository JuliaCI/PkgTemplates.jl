const TEST_UUID = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
const TEST_DEP = PackageSpec(; name="Test", uuid=TEST_UUID)

const AQUA_UUID = "4c88cf16-eb10-579e-8560-4a9242c79595"
const AQUA_DEP = PackageSpec(; name="Aqua", uuid=AQUA_UUID)

"""
    Tests(;
        file="$(contractuser(default_file("test", "runtests.jl")))",
        project=false,
        aqua=false,
    )

Sets up testing for packages.

## Keyword Arguments
- `file::AbstractString`: Template file for `runtests.jl`.
- `project::Bool`: Whether or not to create a new project for tests (`test/Project.toml`).
  See [the Pkg docs](https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1)
  for more details.
- `aqua::Bool`: Whether or not to add quality tests with [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl).

!!! note
    Managing test dependencies with `test/Project.toml` is only supported
    in Julia 1.2 and later.
"""
@plugin struct Tests <: FilePlugin
    file::String = default_file("test", "runtests.jl")
    project::Bool = false
    aqua::Bool = false
end

source(p::Tests) = p.file
destination(::Tests) = joinpath("test", "runtests.jl")

function view(p::Tests, ::Template, pkg::AbstractString)
    d = Dict("PKG" => pkg)
    if p.aqua
        d["AQUA_IMPORT"] = ", Aqua"
        d["AQUA_TESTSET"] = """

            @testset verbose = true "Code quality (Aqua.jl)" begin
                Aqua.test_all($pkg)
            end
        """[begin:end-1]
    else
        d["AQUA_IMPORT"] = ""
        d["AQUA_TESTSET"] = ""
    end
    return d
end

function validate(p::Tests, t::Template)
    invoke(validate, Tuple{FilePlugin,Template}, p, t)
    p.project && t.julia < v"1.2" && @warn string(
            "Tests: The project option is set to create a project (supported in Julia 1.2 and later) ",
            "but a Julia version older than 1.2 ($(t.julia)) is supported by the template",
        )
end

function hook(p::Tests, t::Template, pkg_dir::AbstractString)
    # Do the normal FilePlugin behaviour to create the test script.
    invoke(hook, Tuple{FilePlugin,Template,AbstractString}, p, t, pkg_dir)

    # Then set up the test depdendency in the chosen way.
    if p.project
        make_test_project(p, pkg_dir)
    else
        add_test_dependency(p, pkg_dir)
    end
end

# Create a new test project.
function make_test_project(p::Tests, pkg_dir::AbstractString)
    with_project(() -> Pkg.add(TEST_DEP), joinpath(pkg_dir, "test"))
    if p.aqua
        with_project(() -> Pkg.add(AQUA_DEP), joinpath(pkg_dir, "test"))
    end
end

# Add Test as a test-only dependency.
function add_test_dependency(p::Tests, pkg_dir::AbstractString)
    # Add the dependency manually since there's no programmatic way to add to [extras].
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    if p.aqua
        get!(toml, "extras", Dict())["Aqua"] = AQUA_UUID
    end
    get!(toml, "extras", Dict())["Test"] = TEST_UUID
    get!(toml, "targets", Dict())["test"] = p.aqua ? ["Aqua", "Test"] : ["Test"]
    write_project(path, toml)

    # Generate the manifest by updating the project.
    touch(joinpath(pkg_dir, "Manifest.toml"))  # File must exist to be modified by Pkg.
    with_project(Pkg.update, pkg_dir)
end

function badges(p::Tests)
    bs = Badge[]
    if p.aqua
        b = Badge(
            "Aqua",
            "https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg",
            "https://github.com/JuliaTesting/Aqua.jl",
        )
        push!(bs, b)
    end
    return bs
end
