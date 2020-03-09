const TemplateOrPlugin = Union{Template, Plugin}

function interactive(::Type{T}) where T <: TemplateOrPlugin
    names = setdiff(fieldnames(T), not_customizable(T))
    pairs = map(name -> name => fieldtype(T, name), names)
    foreach(pair -> pair.first in names || push!(pairs, pair), extra_customizable(T))
    isempty(pairs) && return T()
    just_one = length(pairs) == 1
    just_one && push!(pairs, "None")
    menu = MultiSelectMenu(collect(map(pair -> string(first(pair)), pairs)))
    println("$(nameof(T)) keywords to customize:")
    customize = collect(request(menu))
    just_one && delete!(customize, lastindex(pairs))
    kwargs = Dict{Symbol, Any}()
    foreach(map(i -> pairs[i], customize)) do (name, F)
        kwargs[name] = prompt(T, F, name)
    end
    return T(; kwargs...)
end

function pretty_message(s::AbstractString)
    replacements = [
        r"Array{(.*?),1}" => s"Vector{\1}",
        r"Union{Nothing, (.*?)}" => s"Union{\1, Nothing}",
    ]
    return reduce((s, p) -> replace(s, p), replacements; init=s)
end

"""
    not_customizable(::Type{<:Plugin}) -> Vector{Symbol}

Return a list of fields of the given plugin type that are not to be customized.
"""
not_customizable(::Type{T}) where T <: TemplateOrPlugin = ()

"""
    extra_customizable(::Type{<:Plugin}) -> Vector{Symbol}

Return a list of keyword arguments that the given plugin type accepts,
which are not fields of the type.
"""
extra_customizable(::Type{T}) where T <: Plugin = ()

input_tips(T::Type{<:Vector}) = ["comma-delimited", input_tips(eltype(T))...]
input_tips(::Type{Union{T, Nothing}}) where T = ["empty for nothing", input_tips(T)...]
input_tips(::Type{Secret}) = ["name only"]
input_tips(::Type) = []

convert_input(::Type{<:TemplateOrPlugin}, ::Type{String}, s::AbstractString) = string(s)
convert_input(::Type{<:TemplateOrPlugin}, ::Type{VersionNumber}, s::AbstractString) = VersionNumber(s)
convert_input(::Type{<:TemplateOrPlugin}, ::Type{T}, s::AbstractString) where T <: Real = parse(T, s)
convert_input(::Type{<:TemplateOrPlugin}, ::Type{Secret}, s::AbstractString) = Secret(s)
convert_input(::Type{<:TemplateOrPlugin}, ::Type{Bool}, s::AbstractString) = startswith(s, r"[ty]"i)

function convert_input(P::Type{<:TemplateOrPlugin}, T::Type{<:Vector}, s::AbstractString)
    xs = map(strip, split(s, ","))
    return map(x -> convert_input(P, eltype(T), x), xs)
end

"""
    prompt(P::Type{<:Plugin}, ::Type{T}, ::Val{name::Symbol}) -> Any

Prompts for an input of type `T` for field `name` of plugin type `P`.
Implement this method to customize interactive logic for particular fields.
"""
prompt(P::Type{<:TemplateOrPlugin}, T::Type, name::Symbol) = prompt(P, T, Val(name))

function prompt(P::Type{<:TemplateOrPlugin}, ::Type{T}, ::Val{name}) where {T, name}
    tips = join(filter(x -> x !== nothing, [T, input_tips(T)...]), ", ")
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
    types = collect(request(menu))
    return map(i -> interactive(options[i]), types)
end

function prompt(::Type{Template}, ::Type, ::Val{:disable_defaults})
    options = map(typeof, default_plugins())
    menu = MultiSelectMenu(map(string, options))
    println("Select default plugins to disable:")
    types = collect(request(menu))
    return collect(map(i -> options[i], types))
end

function fallback_prompt(::Type{T}, name::Symbol) where T
    return invoke(
        prompt,
        Tuple{Type{Plugin}, Type{T}, Val{name}},
        Plugin, T, Val(:name),
    )
end

concretes(T::Type) = isconcretetype(T) ? Any[T] : vcat(map(concretes, subtypes(T))...)
