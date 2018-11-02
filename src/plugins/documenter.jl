"""
Add a `Documenter` subtype to a template's plugins to add support for documentation
generation via [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
 """
abstract type Documenter <: CustomPlugin end

function gen_plugin(p::Documenter, t::Template, pkg_name::AbstractString)
    path = joinpath(t.dir, pkg_name)
    docs_dir = joinpath(path, "docs", "src")
    mkpath(docs_dir)

    tab = repeat(" ", 4)
    assets_string = if !isempty(p.assets)
        mkpath(joinpath(docs_dir, "assets"))
        for file in p.assets
            cp(file, joinpath(docs_dir, "assets", basename(file)))
        end

        # We want something that looks like the following:
        # [
        #         assets/file1,
        #         assets/file2,
        #     ]
        s = "[\n"
        for asset in p.assets
            s *= """$(tab^2)"assets/$(basename(asset))",\n"""
        end
        s *= "$tab]"

        s
    else
        "[]"
    end

    kwargs_string = if :additional_kwargs in fieldnames(typeof(p))
        set_kwargs = ["modules", "format", "pages", "repo", "sitename", "authors", "assets"]

        # We want something that looks like the following:
        #     key1="val1",
        #     key2="val2",
        #
        kwargs = (x for x in p.additional_kwargs if first(x) ∉ set_kwargs)
        join(string(tab, first(p), "=", repr(last(p)), ",\n") for p in kwargs)
    else
        ""
    end

    make = """
        using Documenter, $pkg_name

        makedocs(;
            modules=[$pkg_name],
            format=:html,
            pages=[
                "Home" => "index.md",
            ],
            repo="https://$(t.host)/$(t.user)/$pkg_name.jl/blob/{commit}{path}#L{line}",
            sitename="$pkg_name.jl",
            authors="$(t.authors)",
            assets=$assets_string,
        $kwargs_string)
        """
    docs = """
    # $pkg_name.jl

    ```@index
    ```

    ```@autodocs
    Modules = [$pkg_name]
    ```
    """

    gen_file(joinpath(dirname(docs_dir), "make.jl"), make)
    gen_file(joinpath(docs_dir, "index.md"), docs)
end

function Base.show(io::IO, p::Documenter)
    spc = "  "
    println(io, "$(nameof(typeof(p))):")

    n = length(p.assets)
    s = n == 1 ? "" : "s"
    print(io, "$spc→ $n asset file$s")
    if n == 0
        println(io)
    else
        println(io, ": $(join(map(a -> replace(a, homedir() => "~"), p.assets), ", "))")
    end

    n = length(p.gitignore)
    s = n == 1 ? "" : "s"
    print(io, "$spc→ $n gitignore entrie$s")
    n > 0 && print(io, ": $(join(map(g -> "\"$g\"", p.gitignore), ", "))")
end

function interactive(t::Type{<:Documenter})
    name = string(nameof(t))
    print("$name: Enter any Documenter asset files (separated by spaces) []: ")
    return t(; assets=string.(split(readline())))
end
