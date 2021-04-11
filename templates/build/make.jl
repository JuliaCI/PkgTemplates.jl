using Pkg; Pkg.activate(@__DIR__)
using PackageCompiler

# List of packages to include in the sysimage
{{#SYSIMAGE_DEPS}}packages = Symbol.(keys(Pkg.project().dependencies))  # or packages = [:Plots, :DataFrames]
{{/SYSIMAGE_DEPS}}
{{@SYSIMAGE_LIST}}packages = [
{{/SYSIMAGE_LIST}}
  {{#SYSIMAGE_LIST}}
    :{{{.}}},
  {{/SYSIMAGE_LIST}}
{{@SYSIMAGE_LIST}}]
{{/SYSIMAGE_LIST}}

# Sysimage name
sysimage_name = "{{{SYSIMAGE_NAME}}}"

sysimage_ext = if Sys.iswindows()
    ".dll"
elseif Sys.isapple()
    ".dylib"
else
    ".so"
end

create_sysimage(
    packages,
    sysimage_path = sysimage_name * sysimage_ext,
    precompile_execution_file = joinpath(@__DIR__, "precompile.jl"),
)
