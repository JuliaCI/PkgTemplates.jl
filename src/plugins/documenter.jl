const DOCUMENTER_UUID = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
const STANDARD_KWS = [:modules, :format, :pages, :repo, :sitename, :authors, :assets]

"""
Add a `Documenter` subtype to a template's plugins to add support for documentation
generation via [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

By default, the plugin generates a minimal index.md and a make.jl file. The make.jl
file contains the Documenter.makedocs command with predefined values for `modules`,
`format`, `pages`, `repo`, `sitename`, and `authors`.

The subtype is expected to include the following fields:
* `assets::Vector{AbstractString}`, a list of filenames to be included as the `assets`
kwarg to `makedocs`
* `gitignore::Vector{AbstractString}`, a list of files to be added to the `.gitignore`

It may optionally include the field `additional_kwargs::Union{AbstractDict, NamedTuple}`
to allow additional kwargs to be added to `makedocs`.
"""
abstract type Documenter <: CustomPlugin end

function gen_plugin(p::Documenter, t::Template, pkg_name::AbstractString)
    path = joinpath(t.dir, pkg_name)
    docs_dir = joinpath(path, "docs")
    mkpath(docs_dir)

    # Create the documentation project.
    proj = Base.current_project()
    try
        Pkg.activate(docs_dir)
        Pkg.add(PackageSpec(; name="Documenter", uuid=DOCUMENTER_UUID))
    finally
        proj === nothing ? Pkg.activate() : Pkg.activate(proj)
    end

    tab = repeat(" ", 4)
    assets_string = if !isempty(p.assets)
        mkpath(joinpath(docs_dir, "src", "assets"))
        for file in p.assets
            cp(file, joinpath(docs_dir, "src", "assets", basename(file)))
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

    kwargs_string = if :additional_kwargs in fieldnames(typeof(p)) &&
        fieldtype(typeof(p), :additional_kwargs) <: Union{AbstractDict, NamedTuple}
        # We want something that looks like the following:
        #     key1="val1",
        #     key2="val2",
        #
        kws = [keys(p.additional_kwargs)...]
        valid_keys = filter(k -> !in(Symbol(k), STANDARD_KWS), kws)
        if length(p.additional_kwargs) > length(valid_keys)
            invalid_keys = filter(k -> Symbol(k) in STANDARD_KWS, kws)
            @warn string(
                "Ignoring predefined Documenter kwargs ",
                join(map(repr, invalid_keys), ", "),
                " from additional kwargs"
            )
        end
        join(map(k -> string(tab, k, "=", repr(p.additional_kwargs[k]), ",\n"), valid_keys))
    else
        ""
    end

    make = """
        using Documenter, $pkg_name

        makedocs(;
            modules=[$pkg_name],
            format=Documenter.HTML(),
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

    gen_file(joinpath(docs_dir, "make.jl"), make)
    gen_file(joinpath(docs_dir, "src", "index.md"), docs)
end

function Base.show(io::IO, p::Documenter)
    spc = "  "
    println(io, nameof(typeof(p)), ":")

    n = length(p.assets)
    s = n == 1 ? "" : "s"
    print(io, spc, "→ $n asset file$s")
    if n == 0
        println(io)
    else
        println(io, ": ", join(map(a -> replace(a, homedir() => "~"), p.assets), ", "))
    end

    n = length(p.gitignore)
    s = n == 1 ? "" : "s"
    print(io, "$spc→ $n gitignore entrie$s")
    n > 0 && print(io, ": ", join(map(repr, p.gitignore), ", "))
end
