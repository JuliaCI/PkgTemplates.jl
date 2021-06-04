function fixup(tpl::Template, pkg_dir)
    pkg_dir = realpath(pkg_dir)
    ispath(pkg_dir) || throw(ArgumentError("Not a directory."))
    isdir(joinpath(pkg_dir, "src")) || throw(ArgumentError("No `src/` directory."))

    fixable = filter(p -> isfixable(p, pkg_dir), tpl.plugins)
    foreach((prehook, hook, posthook)) do h
        @info "Running $(nameof(h))s"
        foreach(sort(fixable; by=p -> priority(p, h), rev=true)) do p
            h(p, tpl, pkg_dir)
        end
    end
    @info "Fixed up package at $pkg_dir"
    # TODO: some magic to add badges to an existing Readme?!
end
