"""
    Docker(; kwargs...) -> Docker

Add Docker to a template's plugins to create a Dockerfile suitable for building a
Docker image containing the package.

# Keyword Arguments
* `base_image::AbstractString="julia:latest"`: The base image used in the Dockerfile.
* `dockerfile_file::Union{AbstractString, Void}=""`: The path to the Dockerfile template
   to use. If `nothing` is supplied, then no file will be generated.
* `dockerignore_file::Union{AbstractString, Void}=""`: The path to the .dockerignore
  template to use. If `nothing` is supplied, then no file will be generated.
* `system_pkgs::Vector{AbstractString}=String[]`: Linux system packages to install.
* `python_pkgs::Vector{AbstractString}=String[]`: Python packages to install with `pip`.
* `user_image::Bool=true`: Allows the Dockerfile to build a Julia system image which
  includes the package.

# Notes
## Ordering
Linux packages will be installed first, followed by Python packages. Julia will then use
`Pkg.resolve()` to install the packages in this package's REQUIRE file.

## Modification
Package developers are encouraged to modify `requirements.txt` and `system-pkgs.txt` to
reflect new requirements as they would `REQUIRE`.
"""
struct Docker <: Plugin
    base_image::AbstractString
    dockerfile_file::AbstractString
    dockerignore_file::AbstractString
    user_image::Bool
    system_pkgs::Vector{AbstractString}
    python_pkgs::Vector{AbstractString}
    gitignore_files::Vector{AbstractString}

    function Docker(;
        base_image="julia:latest",
        dockerfile_file::Union{AbstractString, Void}="",
        dockerignore_file::Union{AbstractString, Void}="",
        user_image::Bool=true,
        system_pkgs::Vector{AbstractString}=String[],
        python_pkgs::Vector{AbstractString}=String[],
    )
        if dockerfile_file != nothing
            if isempty(dockerfile_file)
                dockerfile_file = joinpath(DEFAULTS_DIR, "Dockerfile")
            end
            if !isfile(dockerfile_file)
                throw(ArgumentError("File $dockerfile_file does not exist"))
            end
        end

        if dockerignore_file != nothing
            if isempty(dockerignore_file)
                dockerignore_file = joinpath(DEFAULTS_DIR, "dockerignore")
            end
            if !isfile(dockerignore_file)
                throw(ArgumentError("File $dockerignore_file does not exist"))
            end
        end

        new(
            base_image, dockerfile_file, dockerignore_file,
            user_image, system_pkgs, python_pkgs, String[],
        )
    end
end

"""
    gen_plugin(plugin::Docker, template::Template, pkg_name::AbstractString) -> Vector{String}

Generate a Dockerfile for running an app-style package and generate dependency files of
different sorts for installation within a Docker container.

# Arguments

* `plugin::Docker`: Plugin whose files are being generated.
* `template::Template`: Template configuration and plugins.
* `pkg_name::AbstractString`: Name of the package.

Returns an array of generated files.
"""
function gen_plugin(plugin::Docker, template::Template, pkg_name::AbstractString)
    pkg_dir = joinpath(template.path, pkg_name)
    return_files = String[]

    if plugin.dockerignore_file != nothing
        push!(return_files, ".dockerignore")
        text = substitute(readstring(plugin.dockerignore_file), pkg_name, template)
        gen_file(joinpath(pkg_dir, ".dockerignore"), text)
    end

    if plugin.dockerfile_file != nothing
        push!(return_files, "Dockerfile")
        view = Dict(
            "BASE_IMAGE" => plugin.base_image,
            "MAINTAINER" => template.authors,
            "!system" => !isempty(plugin.system_pkgs),
            "!python" => !isempty(plugin.python_pkgs),
            "!userimg" => !plugin.user_image,
        )
        text = substitute(readstring(plugin.dockerfile_file), pkg_name, template, view)
        gen_file(joinpath(pkg_dir, "Dockerfile"), text)
    end

    pkg_lists = Dict(
        "system-pkgs.txt" => plugin.system_pkgs,
        "requirements.txt" => plugin.python_pkgs,
    )

    for (file_name, pkg_list) in pkg_lists
        isempty(pkg_list) && continue
        open(joinpath(pkg_dir, file_name), "w") do fp
            for pkg in pkg_list
                println(fp, pkg)
            end
        end
        push!(return_files, file_name)
    end

    return return_files
end
