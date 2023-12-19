"""
    generate([pkg::AbstractString]) -> Template

Shortcut for `Template(; interactive=true)(pkg)`.
If no package name is supplied, you will be prompted for one.
"""
function generate(pkg::AbstractString=prompt(Template, String, :pkg))
    t = Template(; interactive=true)
    t(pkg)
    return t
end

"""
    interactive(T::Type{<:Plugin}) -> T

Interactively create a plugin of type `T`. Implement this method and ignore other
related functions only if you want completely custom behaviour.
"""
function interactive(T::Type)
    pairs = Vector{Pair{Symbol, Type}}(interactive_pairs(T))

    # There must be at least 2 MultiSelectMenu options.
    # If there are none, return immediately.
    # If there's just one, add a "dummy" option.
    isempty(pairs) && return T()
    just_one = length(pairs) == 1
    just_one && push!(pairs, :None => Nothing)

    menu = MultiSelectMenu(
        collect(map(pair -> string(first(pair)), pairs));
        pagesize=length(pairs),
    )
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

struct NotCustomizable end

"""
    customizable(::Type{<:Plugin}) -> Vector{Pair{Symbol, DataType}}

Return a list of keyword arguments that the given plugin type accepts,
which are not fields of the type, and should be customizable in interactive mode.
For example, for a constructor `Foo(; x::Bool)`, provide `[x => Bool]`.
If `T` has fields which should not be customizable, use `NotCustomizable` as the type.
"""
customizable(::Type) = ()

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
input_tips(::Type{Vector{T}}) where T = [input_tips(T)..., "comma-delimited"]
input_tips(::Type{Union{T, Nothing}}) where T = [input_tips(T)..., input_tips(Nothing)...]
input_tips(::Type{Nothing}) = ["'nothing' for nothing"]
input_tips(::Type{Secret}) = ["name only"]
# Show expected input type as a tip if it's anything other than `String`
input_tips(::Type{T}) where T = String[string(T)]
input_tips(::Type{String}) = String[]
input_tips(::Type{<:Signed}) = ["Int"]  # Specific Int type likely not important

"""
    convert_input(::Type{P}, ::Type{T}, s::AbstractString) -> T

Convert the user input `s` into an instance of `T` for plugin of type `P`.
A default implementation of `T(s)` exists.
"""
convert_input(::Type, T::Type{<:Real}, s::AbstractString) = parse(T, s)
convert_input(::Type, T::Type, s::AbstractString) = T(s)

function convert_input(P::Type, ::Type{Union{T, Nothing}}, s::AbstractString) where T
    # This is kind of sketchy because technically, there might be some other input
    # whose value we want to instantiate with the string "nothing",
    # but I think that would be a pretty rare occurrence.
    # If that really happens, they can just override this method.
    return s == "nothing" ? nothing : convert_input(P, T, s)
end

function convert_input(P::Type, ::Type{Union{T, Symbol, Nothing}}, s::AbstractString) where T
    # Assume inputs starting with ':' char are intended as Symbols, if a plugin accept symbols.
    # i.e. assume the set of valid Symbols the plugin expects can be spelt starting with ':'.
    return if startswith(s, ":")
        Symbol(chop(s, head=1, tail=0))  # remove ':'
    else
        convert_input(P, Union{T,Nothing}, s)
    end
end

function convert_input(::Type, ::Type{Bool}, s::AbstractString)
    s = lowercase(s)
    return if startswith(s, 't') || startswith(s, 'y')
        true
    elseif startswith(s, 'f') || startswith(s, 'n')
        false
    else
        throw(ArgumentError("Unrecognized boolean response"))
    end
end

function convert_input(P::Type, T::Type{<:Vector}, s::AbstractString)
    startswith(s, '[') && endswith(s, ']') && (s = s[2:end-1])
    xs = map(x -> strip(x, [' ', '\t', '"']), split(s, ","))
    return map(x -> convert_input(P, eltype(T), x), xs)
end

# how would the user type `x` in interactive mode?
input_string(x) = string(x)
input_string(x::AbstractString) = isempty(x) ? repr(x) : String(x)
input_string(x::Symbol) = repr(x)

"""
    prompt(::Type{P}, ::Type{T}, ::Val{name::Symbol}) -> Any

Prompts for an input of type `T` for field `name` of plugin type `P`.
Implement this method to customize particular fields of particular types.
"""
prompt(P::Type, T::Type, name::Symbol) = prompt(P, T, Val(name))

# The trailing `nothing` is a hack for `fallback_prompt` to use, ignore it.
function prompt(P::Type, ::Type{T}, ::Val{name}, ::Nothing=nothing) where {T, name}
    default = defaultkw(P, name)
    tips = join([input_tips(T); "default: $(input_string(default))"], ", ")
    input = Base.prompt(pretty_message("Enter value for '$name' ($tips)"))
    input === nothing && throw(InterruptException())
    input = strip(input, '"')
    return if isempty(input)
        default
    else
        try
            # Working around what appears to be a bug in Julia 1.0:
            # #145#issuecomment-623049535
            if VERSION < v"1.1" && T isa Union && Nothing <: T
                if input == "nothing"
                    nothing
                else
                    convert_input(P, T.a === Nothing ? T.b : T.a, input)
                end
            else
                convert_input(P, T, input)
            end
        catch ex
            ex isa InterruptException && rethrow()
            @warn "Invalid input" ex
            prompt(P, T, name)
        end
    end
end

# Compute all the concrete subtypes of T.
concretes_rec(T::Type) = isabstracttype(T) ? vcat(map(concretes_rec, subtypes(T))...) : Any[T]
concretes(T::Type) = sort!(concretes_rec(T); by=nameof)

# Compute name => type pairs for T's interactive options.
function interactive_pairs(T::Type)
    pairs = collect(map(name -> name => fieldtype(T, name), fieldnames(T)))

    # Use prepend! here so that users can override field types if they wish.
    prepend!(pairs, reverse(customizable(T)))
    uniqueby!(first, pairs)
    filter!(p -> last(p) !== NotCustomizable, pairs)
    sort!(pairs; by=first)

    return pairs
end

# unique!(f, xs) added here: https://github.com/JuliaLang/julia/pull/30141
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
