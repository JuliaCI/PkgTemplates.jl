# Printing utils.
const TAB = repeat(' ', 4)
const HALFTAB = repeat(' ', 2)
const DOT = "• "
const ARROW = "→ "
const PLUGIN_TYPES = let
    leaves(T::Type) = isabstracttype(T) ? vcat(map(leaves, subtypes(T))...) : [T]
    leaves(Plugin)
end

yesno(x::Bool) = x ? "Yes" : "No"

maybe_string(s::AbstractString) = isempty(s) ? "None" : string(s)

"""
    interactive(T::Type{<:Plugin}) -> T

Interactively create a plugin of type `T`.
When this method is implemented for a type, it becomes available to [`Template`](@ref)s created with `interactive=true`.
"""
function interactive end

function make_template(::Val{true}; kwargs...)
    @info "Default values are shown in [brackets]"

    opts = Dict{Symbol, Any}()
    fast = get(kwargs, :fast, false)

    opts[:user] = get(kwargs, :user) do
        default = defaultkw(:user)
        default = isempty(default) ? nothing : default
        prompt_string("Username", default)
    end

    git = opts[:git] = get(kwargs, :git) do
        default = defaultkw(:git)
        fast ? default : prompt_bool("Create Git repositories for packages", default)
    end

    opts[:host] = get(kwargs, :host) do
        default = defaultkw(:host)
        if fast || !git
            default
        else
            prompt_string("Code hosting service", default)
        end
    end

    opts[:license] = get(kwargs, :license) do
        default = defaultkw(:license)
        if fast
            default
        else
            # TODO: Break this out into something reusable?
            choices = String["None"; split(sprint(available_licenses), "\n")]
            licenses = ["" => "", pairs(LICENSES)...]
            menu = RadioMenu(choices)
            first(licenses[request("License:", menu)])
        end
    end

    opts[:authors] = get(kwargs, :authors) do
        default = defaultkw(:authors)
        if fast || !git
            default
        else
            prompt_string("Package author(s)", isempty(default) ? "None" : default)
        end
    end

    opts[:dir] = get(kwargs, :dir) do
        default = defaultkw(:dir)
        fast ? default : prompt_string("Path to package directory", default)
    end

    opts[:julia_version] = get(kwargs, :julia_version) do
        default = defaultkw(:julia_version)
        if fast
            default
        else
            VersionNumber(prompt_string("Minimum Julia version", string(default)))
        end
    end

    opts[:ssh] = get(kwargs, :ssh) do
        default = defaultkw(:ssh)
        fast || !git ? default : prompt_bool("Set remote to SSH", default)
    end

    opts[:manifest] = get(kwargs, :manifest) do
        default = defaultkw(:manifest)
        fast || !git ? default : prompt_bool("Commit Manifest.toml", default)
    end

    opts[:develop] = get(kwargs, :develop) do
        default = defaultkw(:develop)
        fast || !git ? default : prompt_bool("Develop generated packages", default)
    end

    opts[:plugins] = get(kwargs, :plugins) do
        # TODO: Break this out into something reusable?
        types = filter(T -> applicable(interactive, T), PLUGIN_TYPES)
        menu = MultiSelectMenu(map(string ∘ nameof, types))
        selected = types[collect(request("Plugins:", menu))]
        map(interactive, selected)
    end

    return make_template(Val(false); opts...)
end

prompt_string(s::AbstractString, default=nothing) = prompt(string, s, default)

function prompt_bool(s::AbstractString, default=nothing)
    return prompt(s, default) do answer
        answer = lowercase(answer)
        if answer in ["yes", "true", "y", "t"]
            true
        elseif answer in ["no", "false", "n", "f"]
            false
        else
            throw(ArgumentError("Invalid yes/no response"))
        end
    end
end

function prompt(f::Function, s::AbstractString, default)
    required = default === nothing
    default_display = default isa Bool ? yesno(default) : default
    print(s, " [", required ? "REQUIRED" : default_display, "]: ")
    answer = readline()
    return if isempty(answer)
        required && throw(ArgumentError("This argument is required"))
        default
    else
        f(answer)
    end
end

function prompt_config(T::Type{<:BasicPlugin})
    s = "$(nameof(T)): Source file template path"
    default = source(T)
    default === nothing && (s *= " (\"None\" for no file)")
    answer = prompt_string(s, default === nothing ? "None" : contractuser(default))

    return if lowercase(answer) == "none"
        nothing
    elseif isempty(answer)
        default
    else
        answer
    end
end
