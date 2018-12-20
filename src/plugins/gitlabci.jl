"""
    GitLabCI(; config_file::Union{AbstractString, Nothing}="", coverage::Bool=true) -> GitLabCI

Add `GitLabCI` to a template's plugins to add a `.gitlab-ci.yml` configuration file to
generated repositories, and appropriate badge(s) to the README.

# Keyword Arguments:
* `config_file::Union{AbstractString, Nothing}=""`: Path to a custom `.gitlab-ci.yml`.
  If `nothing` is supplied, no file will be generated.
* `coverage::Bool=true`: Whether or not GitLab CI's built-in code coverage analysis should
  be enabled.
"""
struct GitLabCI <: GenericPlugin
    gitignore::Vector{String}
    src::Union{String, Nothing}
    dest::String
    badges::Vector{Badge}
    view::Dict{String, Any}

    function GitLabCI(; config_file::Union{AbstractString, Nothing}="", coverage::Bool=true)
        if config_file != nothing
            config_file = if isempty(config_file)
                config_file = joinpath(DEFAULTS_DIR, "gitlab-ci.yml")
            elseif isfile(config_file)
                abspath(config_file)
            else
                throw(ArgumentError("File $(abspath(config_file)) does not exist"))
            end
        end
        badges = [
            Badge(
                "Build Status",
                "https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/badges/master/build.svg",
                "https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/pipelines",
            ),
        ]
        if coverage
            push!(
                badges,
                Badge(
                    "Coverage",
                    "https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/badges/master/coverage.svg",
                    "https://gitlab.com/{{USER}}/{{PKGNAME}}.jl/commits/master",
                ),
            )
        end

        new(
            coverage ? ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"] : [],
            config_file,
            ".gitlab-ci.yml",
            badges,
            Dict("GITLABCOVERAGE" => coverage),
        )
    end
end

function interactive(::Type{GitLabCI})
    name = "GitLabCI"
    kwargs = Dict{Symbol, Any}()
    default_config_file = joinpath(DEFAULTS_DIR, "gitlab-ci.yml")

    print("$name: Enter the config template filename (\"None\" for no file) ")
    print("[", replace(default_config_file, homedir() => "~"), "]: ")
    config_file = readline()
    kwargs[:config_file] = if uppercase(config_file) == "NONE"
        nothing
    elseif isempty(config_file)
        default_config_file
    else
        config_file
    end

    print("$name: Enable test coverage analysis? [yes]: ")
    coverage = readline()
    kwargs[:coverage] = if isempty(coverage)
        true
    else
        !in(uppercase(coverage), ["N", "NO", "FALSE", "NONE"])
    end

    return GitLabCI(; kwargs...)
end
