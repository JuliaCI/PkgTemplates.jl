import PackageCompiler, TOML

if length(ARGS) < 1 || length(ARGS) > 2
    println("Usage: julia $PROGRAM_FILE target_dir [major|minor]")
    println()
    println("where:")
    println("    target_dir is the directory to use to create the library bundle")
    println("    [major|minor] is the (optional) compatibility version (default: major).")
    println("                  Use 'minor' if you use new/non-backwards-compatible functionality.")
    println()
    println("[major|minor] is only useful on OSX.")
    exit(1)
end

const build_dir = @__DIR__
const target_dir = ARGS[1]
const project_toml = realpath(joinpath(build_dir, "..", "Project.toml"))
const version = VersionNumber(TOML.parsefile(project_toml)["version"])

const compatibility = length(ARGS) == 2 ? ARGS[2] : "major"

PackageCompiler.create_library(".", target_dir;
                            lib_name="{{{LIB}}}",
                            precompile_execution_file=[joinpath(build_dir, "generate_precompile.jl")],
                            precompile_statements_file=[joinpath(build_dir, "additional_precompile.jl")],
                            incremental=false,
                            filter_stdlibs=true,
                            header_files = [joinpath(build_dir, "{{{LIB}}}.h")],
                            force=true,
                            version=version,
                            compat_level=compatibility,
                        )
