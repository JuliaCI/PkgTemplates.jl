using PkgTemplates
using Test
using Dates
using LibGit2
using Pkg

import PkgTemplates: badges, version_floor, substitute, read_license, gen_file, gen_readme,
    gen_tests, gen_license, gen_require, gen_gitignore, gen_plugin, show_license, LICENSES,
    LICENSE_DIR, Plugin, GenericPlugin, CustomPlugin, Badge, format, interactive,
    DEFAULTS_DIR, Documenter

mktempdir() do temp_dir
    mkdir(joinpath(temp_dir, "dev"))
    pushfirst!(DEPOT_PATH, temp_dir)
    cd(temp_dir) do
        @testset "PkgTemplates.jl" begin
            include("tests.jl")
        end
    end
end
