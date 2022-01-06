using PkgTemplates: @plugin, @with_kw_noshow, Plugin

# Used to generate the library name
camel_to_snake_case(str::AbstractString) = replace(str, r"([a-z])([A-Z]+)" => s"\1_\2") |> lowercase

"""
    PackageCompilerLib(;
        lib_name=nothing,
        build_jl="$(contractuser(default_file("build", "build.jl")))",
        generate_precompile_jl="$(contractuser(default_file("build", "generate_precompile.jl")))",
        additional_precompile_jl="$(contractuser(default_file("build", "additional_precompile.jl")))",
        install_sh="$(contractuser(default_file("build", "install.sh")))",
        install_txt="$(contractuser(default_file("build", "INSTALL.txt")))",
        lib_h="$(contractuser(default_file("build", "lib.h")))",
        project_toml="$(contractuser(default_file("build", "Project.toml")))",
        makefile="$(contractuser(default_file("Makefile")))",
        additional_gitignore=[],
    )

Adds files which facilitate the creation of a C-library from the generated project.

See [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl) for more information.

## Keyword Arguments
- `lib_name::Union{String, Nothing}`: Name of the library to generate. If `nothing`,
  defaults to the snake-case version of the package name.
- `build_jl::String`: The file used to generate the C library. Calls out to `PackageCompiler.jl`.
- `generate_precompile_jl::String`: File with a code which will be used to generate precompile statements.
- `additional_precompile_jl::String`: File with additional precompile statements.
- `install_sh::String`: Installation script for the generated library.
- `install_txt::String`: Installation instructions for the generated library.
- `lib_h::String`: C header file for the generated library.
- `project_toml::String`: Julia `Project.toml` for the build directory.
- `makefile::String`: Makefile with targets to help build the C library.
- `additional_gitignore::Vector{String}`: Additional strings to add to .gitignore.

"""
@plugin struct PackageCompilerLib <: Plugin
    lib_name::Union{String, Nothing} = nothing
    build_jl::String = default_file("build", "build.jl")
    generate_precompile_jl::String = default_file("build", "generate_precompile.jl")
    additional_precompile_jl::String = default_file("build", "additional_precompile.jl")
    install_sh::String = default_file("build", "install.sh")
    install_txt::String = default_file("build", "INSTALL.txt")
    lib_h::String = default_file("build", "lib.h")
    project_toml::String = default_file("build", "Project.toml")
    makefile::String = default_file("Makefile")
    additional_gitignore::Vector{String} = []
end

function validate(p::PackageCompilerLib, ::Template)
    isfile(p.build_jl) || throw(ArgumentError("PackageCompilerLib: $(p.build_jl) does not exist"))
    isfile(p.additional_precompile_jl) || throw(ArgumentError("PackageCompilerLib: $(p.additional_precompile_jl) does not exist"))
    isfile(p.generate_precompile_jl) || throw(ArgumentError("PackageCompilerLib: $(p.generate_precompile_jl) does not exist"))
    isfile(p.install_sh) || throw(ArgumentError("PackageCompilerLib: $(p.install_sh) does not exist"))
    isfile(p.install_txt) || throw(ArgumentError("PackageCompilerLib: $(p.install_txt) does not exist"))
    isfile(p.lib_h) || throw(ArgumentError("PackageCompilerLib: $(p.lib_h) does not exist"))
    isfile(p.project_toml) || throw(ArgumentError("PackageCompilerLib: $(p.project_toml) does not exist"))
    isfile(p.makefile) || throw(ArgumentError("PackageCompilerLib: $(p.makefile) does not exist"))
end

view(p::PackageCompilerLib, t::Template, pkg::AbstractString) = Dict(
    "PKG" => pkg,
    "LIB" => lib_name(p, pkg),
)

function lib_name(p::PackageCompilerLib, pkg::AbstractString)
    p.lib_name !== nothing ? p.lib_name : camel_to_snake_case(pkg)
end

function gitignore(p::PackageCompilerLib)
    ignore_files = ["build/Manifest.toml", "target"]
    append!(ignore_files, p.additional_gitignore)
    return ignore_files
end

function prehook(p::PackageCompilerLib, t::Template, pkg_dir::AbstractString)
    # The library name and version are used as the default Makefile output target
    # (e.g. the library is built under mylib-0.1.0/).
    # If we use a the default library name, p.lib_name === nothing, then the
    # gitignore() function won't have access to the default library name.
    # To work around this, we get the library name and store the output target directory
    # glob here in the prehook, so it can be added by gitignore() later.
    pkg = basename(pkg_dir)
    library_name = lib_name(p, pkg)
    push!(p.additional_gitignore, "/$(library_name)-*")
end

function hook(p::PackageCompilerLib, t::Template, pkg_dir::AbstractString)
    build_dir = joinpath(pkg_dir, "build")
    pkg = basename(pkg_dir)
    library_name = lib_name(p, pkg)

    build_jl = render_file(p.build_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "build.jl"), build_jl)

    additional_precompile_jl = render_file(p.additional_precompile_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "additional_precompile.jl"), additional_precompile_jl)

    generate_precompile_jl = render_file(p.generate_precompile_jl, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "generate_precompile.jl"), generate_precompile_jl)

    install_sh = render_file(p.install_sh, combined_view(p, t, pkg), tags(p))
    install_sh_target = joinpath(build_dir, "install.sh")
    gen_file(install_sh_target, install_sh)
    chmod(install_sh_target, 0o755)

    install_txt = render_file(p.install_txt, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "INSTALL.txt"), install_txt)

    lib_h = render_file(p.lib_h, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "$(library_name).h"), lib_h)

    project_toml = render_file(p.project_toml, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(build_dir, "Project.toml"), project_toml)

    makefile = render_file(p.makefile, combined_view(p, t, pkg), tags(p))
    gen_file(joinpath(pkg_dir, "Makefile"), makefile)
end
