using PkgTemplates
using Base.Test

# Write your own tests here.
mktempdir() do temp_dir
    withenv("JULIA_PKGDIR" => temp_dir) do
        Pkg.init()
        cd(temp_dir) do
            include("tests.jl")
        end
    end
end
