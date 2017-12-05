using PkgTemplates
using Base.Test

import PkgTemplates: badges, version_floor, substitute, read_license, gen_file, gen_readme,
    gen_tests, gen_license, gen_require, gen_entrypoint, gen_gitignore, gen_plugin,
    show_license, LICENSES, LICENSE_DIR, Plugin, GenericPlugin, CustomPlugin, Badge,
    format, interactive, DEFAULTS_DIR

mktempdir() do temp_dir
    withenv("JULIA_PKGDIR" => temp_dir) do
        # We technically don't need to clone METADATA to run tests.
        if get(ENV, "PKGTEMPLATES_TEST_FAST", "false") == "true"
            mkdir(joinpath(temp_dir, "v$(version_floor())"))
        else
            Pkg.init()
        end
        cd(temp_dir) do
            @testset "PkgTemplates.jl" begin
                include("tests.jl")
            end
        end
    end
end
