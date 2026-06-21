module ExtractCiActionsVersions
using YAML

function collect_uses!(node::Dict, results::Vector{String})
    for (k, v) in node
        if k == "uses" && v isa AbstractString && occursin("@", v)
            push!(results, v)
        end
        collect_uses!(v, results)
    end
    return results
end

function collect_uses!(node::AbstractVector, results::Vector{String})
    for item in node
        collect_uses!(item, results)
    end
    return results
end

function collect_uses!(node, results::Vector{String})
    return results
end

split_versions(results) = Dict{String, String}(split(r, "@", limit=2)[1] => r for r in results)

function extract_ci_actions_versions()
    base_dir = dirname(@__DIR__)
    files_to_parse = [
        joinpath(base_dir, ".github", "workflows", "CI.yml"),
        joinpath(base_dir, ".github", "workflows", "TriggerDependabotUpdate.yml")
    ]
    results = String[]
    for f in files_to_parse
        if isfile(f)
            dict = YAML.load_file(f)
            collect_uses!(dict, results)
        end
    end
    unique!(results)
    return split_versions(results)
end

end # module

const CI_ACTIONS = ExtractCiActionsVersions.extract_ci_actions_versions()

