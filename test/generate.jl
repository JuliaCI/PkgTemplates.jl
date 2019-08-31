default_files(pkg::AbstractString) = [
    ".gitignore",
    "LICENSE",
    "Manifest.toml",
    "Project.toml",
    "README.md",
    "src/$pkg.jl",
    "test/runtests.jl",
]

function reference_test(pkg_dir::AbstractString, path::AbstractString)
    pkg = basename(pkg_dir)
    path = replace(path, "/" => path_separator)
    # All fixture files are .txt because otherwise ReferenceTests/FileIO can't handle them.
    reference = joinpath(@__DIR__, "fixtures", pkg, path * ".txt")
    observed = read(joinpath(pkg_dir, path), String)
    @test_reference reference observed
end

@testset "Default package" begin
    pkg = "Basic"
    t = tpl(; develop=false, authors=USER)
    t(pkg)
    foreach(f -> reference_test(joinpath(t.dir, pkg), f), default_files(pkg))
end
