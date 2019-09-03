# const PLUGIN_TYPES = let
#     leaves(T::Type) = isconcretetype(T) ? [T] : vcat(map(leaves, subtypes(T))...)
#     leaves(Plugin)
# end

function Base.show(io::IO, ::MIME"text/plain", p::T) where T <: Plugin
    indent = get(io, :indent, 0)
    print(io, repeat(' ', indent), T, ":")
    foreach(fieldnames(T)) do n
        println(io)
        print(io, repeat(' ', indent + 2), n, ": ", show_field(getfield(p, n)))
    end
end

show_field(x) = repr(x)
show_field(x::AbstractString) = repr(contractuser(x))

function Base.show(io::IO, m::MIME"text/plain", t::Template)
    println(io, "Template:")
    foreach(fieldnames(Template)) do n
        n === :plugins || println(io, repeat(' ', 2), n, ": ", show_field(getfield(t, n)))
    end
    if isempty(t.plugins)
        print(io, "  plugins: None")
    else
        print(io, repeat(' ', 2), "plugins:")
        foreach(sort(collect(values(t.plugins)); by=string)) do p
            println(io)
            show(IOContext(io, :indent => 4), m, p)
        end
    end
end
