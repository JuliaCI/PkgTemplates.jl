function Base.show(io::IO, ::MIME"text/plain", p::T) where T <: Plugin
    indent = get(io, :indent, 0)
    print(io, repeat(' ', indent), T)
    ns = fieldnames(T)
    isempty(ns) || print(io, ":")
    foreach(ns) do n
        println(io)
        print(io, repeat(' ', indent + 2), n, ": ", show_field(getfield(p, n)))
    end
end

show_field(x) = repr(x)
if Sys.iswindows()
    show_field(x::AbstractString) = replace(repr(contractuser(x)), "\\\\" => "\\")
else
    show_field(x::AbstractString) = repr(contractuser(x))
end

"""
    interactive(::Type{T<:Plugin}) -> T

Create a [`Plugin`](@ref) of type `T` interactively from user input.
"""
function interactive(::Type{T}) where T <: Plugin
    return T()  # TODO
end

function Base.show(io::IO, m::MIME"text/plain", t::Template)
    println(io, "Template:")
    foreach(fieldnames(Template)) do n
        n === :plugins || println(io, repeat(' ', 2), n, ": ", show_field(getfield(t, n)))
    end
    if isempty(t.plugins)
        print(io, "  plugins: None")
    else
        print(io, repeat(' ', 2), "plugins:")
        foreach(sort(t.plugins; by=string)) do p
            println(io)
            show(IOContext(io, :indent => 4), m, p)
        end
    end
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
        opts[:user] = prompt(String, "Git hosting service username", defaultkw(:user))
    end

    if !haskey(opts, :host)
        opts[:host] = prompt(String, "Git hosting service URL", defaultkw(:host))
    end

    if !haskey(opts, :authors)
        opts[:authors] = prompt(String, "Package author(s)", defaultkw(:authors))
    end

    if !haskey(opts, :dir)
        opts[:dir] = prompt(String, "Path to package parent directory", defaultkw(:dir))
    end

    if !haskey(opts, :julia)
        opts[:julia] = prompt(VersionNumber, "Supported Julia version", defaultkw(:julia))
    end

    if !haskey(opts, :disable_defaults)
        available = map(typeof, default_plugins())
        opts[:disable_defaults] = select("Select defaults to disable:", available, [])
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

function prompt(::Type{String}, s::AbstractString, default; required::Bool=false)
    default isa AbstractString && (default = contractuser(default))
    default_display = required ? "REQUIRED" : repr(default)
    print("$s [$default_display]: ")
    input = strip(readline())
    return if isempty(input) && required
        println("This  option is required")
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
    return uppercase(b) in ("Y", "YES", "T", "TRUE")
end

function prompt(::Type{Vector{String}}, s::AbstractString, default::Vector{<:AbstractString})
    # TODO
end

# TODO: These can be made simpler when this is merged:
# https://github.com/JuliaLang/julia/pull/30043

select(s::AbstractString, xs::Vector, initial) = select(string, s, xs, initial)

# Select any number of elements from a collection.
function select(f::Function, s::AbstractString, xs::Vector, initial::Vector)
    m = MultiSelectMenu(map(f, xs); pagesize=length(xs))
    foreach(x -> push!(m.selected, findfirst(==(x), xs)), initial)
    selection = request(s, m)
    return map(i -> xs[i], collect(selection))
end

# Select one item frm oa collection.
function select(f::Function, s::AbstractString, xs::Vector, _initial)
    # Can't use the initial value yet.
    selection = request(s, RadioMenu(map(f, xs)))
    return xs[selection]
end
