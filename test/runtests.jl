using PkgTemplates
using Base.Test

import PkgTemplates: badges, version_floor, substitute, read_license, gen_file, gen_readme,
    gen_tests, gen_license, gen_require, gen_entrypoint, gen_gitignore, gen_plugin

mktempdir() do temp_dir
    withenv("JULIA_PKGDIR" => temp_dir) do
        Pkg.init()
        cd(temp_dir) do
            include("tests.jl")
        end
    end
end
