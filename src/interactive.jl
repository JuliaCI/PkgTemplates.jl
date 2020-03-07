const TemplateOrPlugin = Union{Template, Plugin}

function interactive(::Type{T}) where T <: TemplateOrPlugin
    Fs = setdiff(fieldnames(T), not_customizable(T))
    menu = MultiSelectMenu(collect(map(string, Fs)))
    println("$(nameof(T)) fields to customize:")
    customize = collect(request(menu))

    kwargs = Dict{Symbol, Any}()
    foreach(map(i -> Fs[i], customize)) do name
        kwargs[name] = prompt(T, fieldtype(T, name), name)
    end

    return T(; kwargs...)
end

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

function pretty_message(s::AbstractString)
    replacements = [
        r"Array{(.*?),1}" => s"Vector{\1}",
        r"Union{Nothing, (.*?)}" => s"Union{\1, Nothing}",
    ]
    return reduce((s, p) -> replace(s, p), replacements; init=s)
end

not_customizable(::Type{T}) where T <: TemplateOrPlugin = ()

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
