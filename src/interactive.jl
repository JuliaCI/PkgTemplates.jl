"""
    interactive(::Type{T<:Plugin}) -> T

Create a [`Plugin`](@ref) of type `T` interactively from user input.
"""
function interactive(::Type{T}) where T <: Plugin
    kwargs = Dict{Symbol, Any}()

    foreach(fieldnames(T)) do name
        F = fieldtype(T, name)
        v = Val(name)
        required = !applicable(defaultkw, T, v)
        default = required ? defaultkw(F) : defaultkw(T, v)
        kwargs[name] = if applicable(prompt, T, v)
            prompt(F, "$T: $(prompt(T, v))", default, required=required)
        else
            prompt(F, "$T: Value for field '$name' ($F)", default; required=required)
        end
    end

    return T(; kwargs...)
end

leaves(T::Type) = isconcretetype(T) ? [T] : vcat(map(leaves, subtypes(T))...)

function plugin_types()
    Ts = leaves(Plugin)
    # Hack both Documenter types into the list.
    # Unfortunately there's no way to do this automatically,
    # but it's unlikely for more parametric plugin types to exist.
    push!(Ts, Documenter{TravisCI}, Documenter{GitLabCI})
    return Ts
end

function Template(::Val{true}; kwargs...)
    opts = Dict{Symbol, Any}(kwargs)

    if !haskey(opts, :user)
        default = defaultkw(Template, :user)
        opts[:user] = prompt(String, "Git hosting service username", default)
    end

    if !haskey(opts, :host)
        default = defaultkw(Template, :host)
        opts[:host] = prompt(String, "Git hosting service URL", default)
    end

    if !haskey(opts, :authors)
        default = defaultkw(Template, :authors)
        opts[:authors] = prompt(String, "Package author(s)", default)
    end

    if !haskey(opts, :dir)
        default = defaultkw(Template, :dir)
        opts[:dir] = prompt(String, "Path to package parent directory", default)
    end

    if !haskey(opts, :julia)
        default = defaultkw(Template, :julia)
        opts[:julia] = prompt(VersionNumber, "Supported Julia version", default)
    end

    if !haskey(opts, :disable_defaults)
        available = map(typeof, default_plugins())
        initial = defaultkw(Template, :disable_defaults)
        opts[:disable_defaults] = select("Select defaults to disable:", available, initial)
    end

    if !haskey(opts, :plugins)
        # Don't offer any disabled plugins as options.
        available = setdiff(sort(plugin_types(); by=string), opts[:disable_defaults])
        initial = setdiff(map(typeof, default_plugins()), opts[:disable_defaults])
        chosen = select("Select plugins", available, initial)
        opts[:plugins] = map(interactive, chosen)
    end

    return Template(Val(false); opts...)
end

defaultkw(::Type{String}) = ""
defaultkw(::Type{Union{T, Nothing}}) where T = nothing
defaultkw(::Type{T}) where T <: Number = zero(T)
defaultkw(::Type{Vector{T}}) where T = T[]

function prompt(
    ::Type{<:Union{String, Nothing}}, s::AbstractString, default;
    required::Bool=false,
)
    default isa AbstractString && (default = contractuser(default))
    default_display = if required
        "REQUIRED"
    elseif default === nothing
        "None"
    else
        repr(default)
    end

    print("$s [$default_display]: ")
    input = strip(readline())

    return if isempty(input) && required
        println("This option is required")
        prompt(String, s, default; required=required)
    elseif isempty(input)
        default
    else
        input
    end
end

function prompt(
    ::Type{VersionNumber}, s::AbstractString, default::VersionNumber;
    required::Bool=false,
)
    v = prompt(String, s, default; required=required)
    return if v isa VersionNumber
        v
    else
        startswith(v, "v") && (v = v[2:end])
        v = replace(v, "\"" => "")
        VersionNumber(v)
    end
end

function prompt(::Type{Bool}, s::AbstractString, default::Bool; required::Bool=false)
    b = prompt(String, s, default; required=required)
    return b === default ? default : uppercase(b) in ("Y", "YES", "T", "TRUE")
end

function prompt(::Type{Vector}, s::AbstractString, default::Vector; required::Bool=false)
    return prompt(Vector{String}, s, default; required=required)
end

function prompt(
    ::Type{Vector{String}}, s::AbstractString, default::Vector{<:AbstractString};
    required::Bool=false,
)
    s = prompt(String, "$s (comma-delimited)", join(default, ", "); required=required)
    return convert(Vector{String}, map(strip, split(s, ","; keepempty=false)))
end

function prompt(::Type{<:Dict}, s::AbstractString, default::Dict, required::Bool=false)
    default_display = join(map(p -> "$(p.first)=$(p.second)", collect(default)), ", ")
    s = prompt(String, "$s (k=v, comma-delimited)", default_display; required=required)
    return if isempty(s)
        Dict{String, String}()
    else
        Dict{String, String}(Pair(split(strip(kv), "=")...) for kv in split(s, ","))
    end
end

# TODO: These can be made simpler when this is merged:
# https://github.com/JuliaLang/julia/pull/30043

select(s::AbstractString, xs::Vector, initial) = select(string, s, xs, initial)

# Select any number of elements from a collection.
function select(f::Function, s::AbstractString, xs::Vector, initial::Vector)
    m = MultiSelectMenu(map(f, xs); pagesize=length(xs))
    foreach(x -> push!(m.selected, findfirst(==(x), xs)), initial)
    selection = request("$s:", m)
    return map(i -> xs[i], collect(selection))
end

# Select one item frm oa collection.
function select(f::Function, s::AbstractString, xs::Vector, initial)
    print(stdin.buffer, repeat("\e[B", findfirst(==(initial), xs) - 1))
    selection = request("$s:", RadioMenu(map(f, xs); pagesize=length(xs)))
    return xs[selection]
end
