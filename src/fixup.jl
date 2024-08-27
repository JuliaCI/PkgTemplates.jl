"""
    fixup(tpl::Template, pkg_dir)

Fixes up the package at `pkg_dir` according to the template `tpl`. Returns the path to the fixed package and the path to the backup folder.

## Example

```julia
using PkgTemplates

# Original package:
t = Template(user="my-username", dir="~")
pkg_dir = t("MyPkg.jl")

# Fixup the package (with Documenter plugin):
t = Template(
    user="my-username", dir="~",
    authors="Acme Corp",
    plugins=[
        Documenter{GitHubActions}(),
    ]
)
pkg_dir, backup = fixup(t, pkg_dir)
```
"""
function fixup(tpl::Template, pkg_dir)

    # Assertions:
    pkg_dir = realpath(pkg_dir)
    ispath(pkg_dir) || throw(ArgumentError("Not a directory."))
    isdir(joinpath(pkg_dir, "src")) || throw(ArgumentError("No `src/` directory."))

    # Back up in temporary directory:
    backup = joinpath(tempdir(), splitpath(pkg_dir)[end])
    if !isdir(backup) 
        @info "Fixing up the package at $pkg_dir might require overwriting files.\nThe current state of the package is backed up at $backup. Hit ENTER to continue."
        readline()
        run(`cp -r $pkg_dir $backup`)
    else
        @warn "Existing backup for $pkg_dir found at $backup. Skipping backup. If you are sure that you want to apply the fix-up again, hit ENTER to continue."
        readline()
    end

    # Fix all plugins that are fixable:
    fixable = filter(p -> isfixable(p, pkg_dir), tpl.plugins)
    foreach((prehook, hook, posthook)) do h
        @info "Running $(nameof(h))s"
        foreach(sort(fixable; by=p -> priority(p, h), rev=true)) do p
            h(p, tpl, pkg_dir)
        end
    end
    @info "Fixed up package at $pkg_dir. The old state of the package is backed up at $backup."
    # TODO: some magic to add badges to an existing Readme?!

    return pkg_dir, backup
end
