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

function Base.show(io::IO, ::MIME"text/plain", p::T) where T <: Plugin
    indent = get(io, :indent, 0)
    print(io, repeat(' ', indent), nameof(T))
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
