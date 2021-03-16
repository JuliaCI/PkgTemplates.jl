function fixup(tpl::Template, pkg_dir::AbstractString)
    ispath(pkg_dir) || throw(ArgumentError("Not a directory."))
    isdir(joinpath(pkg_dir, "src")) || throw(ArgumentError("No `src/` directory."))

    fixable = filter(p -> isfixable(p, pkg_dir), tpl.plugins)
    foreach((prehook, hook, posthook)) do h
        @info "Running $(nameof(h))s"
        foreach(sort(fixable; by=p -> priority(p, h), rev=true)) do p
            @info p
            h(p, tpl, pkg_dir)
        end
    end
    # TODO: some magic to add badges to an existing Readme?!
end
