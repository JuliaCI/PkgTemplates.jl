const TemplateOrPlugin = Union{Template, Plugin}

"""
    interactive(T::Type{<:Plugin}) -> T

Interactively create a plugin of type `T`. Implement this method and ignore other
related functions only if you want completely custom behaviour.
"""
function interactive(::Type{T}) where T <: TemplateOrPlugin
    pairs = interactive_pairs(T)

    # There must be at least 2 MultiSelectMenu options.
    # If there are none, return immediately.
    # If there's just one, add a "dummy" option.
    isempty(pairs) && return T()
    just_one = length(pairs) == 1
    just_one && push!(pairs, :None => Nothing)

    menu = MultiSelectMenu(collect(map(pair -> string(first(pair)), pairs)))
    println("$(nameof(T)) keywords to customize:")
    customize = sort!(collect(request(menu)))

    # If the "None" option was selected, don't customize anything.
    just_one && lastindex(pairs) in customize && return T()

    kwargs = Dict{Symbol, Any}()
    foreach(pairs[customize]) do (name, F)
        kwargs[name] = prompt(T, F, name)
    end
    return T(; kwargs...)
end

"""
    not_customizable(::Type{<:Plugin}) -> Vector{Symbol}

Return the names of fields of the given plugin type that cannot be customized
in interactive mode.
"""
not_customizable(::Type{T}) where T <: TemplateOrPlugin = ()

"""
    extra_customizable(::Type{<:Plugin}) -> Vector{Pair{Symbol, DataType}}

Return a list of keyword arguments that the given plugin type accepts,
which are not fields of the type, and should be customizable in interactive mode.
For example, for a constructor `Foo(; x::Bool)`, provide `[x => Bool]`.
"""
extra_customizable(::Type{T}) where T <: Plugin = ()

function pretty_message(s::AbstractString)
    replacements = [
        r"Array{(.*?),1}" => s"Vector{\1}",
        r"Union{Nothing, (.*?)}" => s"Union{\1, Nothing}",
    ]
    return reduce((s, p) -> replace(s, p), replacements; init=s)
end

"""
    input_tips(::Type{T}) -> Vector{String}

Provide some extra tips to users on how to structure their input for the type `T`,
for example if multiple delimited values are expected.
"""
input_tips(T::Type{<:Vector}) = ["comma-delimited", input_tips(eltype(T))...]
input_tips(::Type{Union{T, Nothing}}) where T = ["empty for nothing", input_tips(T)...]
input_tips(::Type{Secret}) = ["name only"]
input_tips(::Type) = String[]

"""
    convert_input(::Type{<:Plugin}, ::Type{T}, s::AbstractString) -> T

Convert the user input `s` into an instance of `T`.
A default implementation of `T(s)` exists.
"""
convert_input(::Type{<:TemplateOrPlugin}, ::Type{String}, s::AbstractString) = string(s)
convert_input(::Type{<:TemplateOrPlugin}, T::Type{<:Real}, s::AbstractString) = parse(T, s)
convert_input(::Type{<:TemplateOrPlugin}, T::Type, s::AbstractString) = T(s)

function convert_input(::Type{<:TemplateOrPlugin}, ::Type{Bool}, s::AbstractString)
    s = lowercase(s)
    return startswith(s, "t") || startswith(s, "y")
end

function convert_input(P::Type{<:TemplateOrPlugin}, T::Type{<:Vector}, s::AbstractString)
    xs = map(strip, split(s, ","))
    return map(x -> convert_input(P, eltype(T), x), xs)
end

"""
    prompt(P::Type{<:Plugin}, ::Type{T}, ::Val{name::Symbol}) -> Any

Prompts for an input of type `T` for field `name` of plugin type `P`.
Implement this method to customize particular fields of particular types.
"""
prompt(P::Type{<:TemplateOrPlugin}, T::Type, name::Symbol) = prompt(P, T, Val(name))

function prompt(P::Type{<:TemplateOrPlugin}, ::Type{T}, ::Val{name}) where {T, name}
    tips = join([T; input_tips(T)], ", ")
    print(pretty_message("Enter value for '$name' ($tips): "))
    input = strip(readline())
    return if isempty(input)
        Nothing <: T ? nothing : prompt(P, T, name)
    else
        try
            convert_input(P, T, input)
        catch e
            e isa InterruptException || e isa MethodError && rethrow()
            @warn "Invalid input" e
            prompt(P, T, name)
        end
    end
end

function prompt(::Type{Template}, ::Type, ::Val{:julia})
    versions = ["1.0", "1.1", "1.2", "1.3", "1.4", format_version(VERSION)]
    push!(sort!(unique!(versions)), "Other")
    menu = RadioMenu(map(string, versions))
    println("Select minimum Julia version:")
    idx = request(menu)
    return if idx == lastindex(versions)
        fallback_prompt(VersionNumber, :julia)
    else
        VersionNumber(versions[idx])
    end
end

function prompt(::Type{Template}, ::Type, ::Val{:host})
    hosts = ["github.com", "gitlab.com", "bitbucket.org", "Other"]
    menu = RadioMenu(hosts)
    println("Select Git repository hosting service:")
    idx = request(menu)
    return if idx == lastindex(hosts)
        fallback_prompt(String, :host)
    else
        hosts[idx]
    end
end

function prompt(::Type{Template}, ::Type, ::Val{:plugins})
    options = concretes(Plugin)
    menu = MultiSelectMenu(map(string, options))
    println("Select plugins:")
    types = sort!(collect(request(menu)))
    return map(interactive, options[types])
end

function prompt(::Type{Template}, ::Type, ::Val{:disable_defaults})
    options = map(typeof, default_plugins())
    menu = MultiSelectMenu(map(string, options))
    println("Select default plugins to disable:")
    types = sort!(collect(request(menu)))
    return options[types]
end

# Call the default prompt method even if a specialized one exists.
function fallback_prompt(::Type{T}, name::Symbol) where T
    return invoke(
        prompt,
        Tuple{Type{Plugin}, Type{T}, Val{name}},
        Plugin, T, Val(name),
    )
end

# Compute name => type pairs for T's interactive options.
function interactive_pairs(::Type{T}) where T <: TemplateOrPlugin
    names = setdiff(fieldnames(T), not_customizable(T))
    pairs = map(name -> name => fieldtype(T, name), names)

    # Use pushfirst! here so that users can override field types if they wish.
    foreach(pair -> pushfirst!(pairs, pair), extra_customizable(T))
    uniqueby!(first, pairs)
    sort!(pairs; by=first)

    return pairs
end

# Compute all the concrete subtypes of T.
concretes_rec(T::Type) = isconcretetype(T) ? Any[T] : vcat(map(concretes_rec, subtypes(T))...)
concretes(T::Type) = sort!(concretes_rec(T); by=nameof)

if VERSION >= v"1.1"
    const uniqueby! = unique!
else
    function uniqueby!(f, xs)
        seen = Set()
        todelete = Int[]
        foreach(enumerate(map(f, xs))) do (i, out)
            out in seen && push!(todelete, i)
            push!(seen, out)
        end
        return deleteat!(xs, todelete)
    end
end
