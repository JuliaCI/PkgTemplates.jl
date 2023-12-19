```@meta
CurrentModule = PkgTemplates
```

# Migrating To PkgTemplates 0.7+

PkgTemplates 0.7 is a ground-up rewrite of the package with similar functionality but with updated APIs and internals.
Here is a summary of things that existed in older versions but have been moved elsewhere or removed.
However, it might be easier to just read the [User Guide](user.md).

## Template keywords

The recurring theme is "everything is a plugin now".

| Old                  | New                               |
| :------------------: | :-------------------------------: |
| `license="ISC"`      | `plugins=[License(; name="ISC")]` |
| `develop=true` *     | `plugins=[Develop()]`             |
| `git=false`          | `plugins=[!Git]`                  |
| `julia_version=v"1"` | `julia=v"1"`                      |
| `ssh=true`           | `plugins=[Git(; ssh=true)]`       |
| `manifest=true`      | `plugins=[Git(; manifest=true)]`  |

\* `develop=true` was the default setting, but it is no longer the default in PkgTemplates 0.7+.

## Plugins

Aside from renamings, basically every plugin has had their constructors reworked.
So if you are using anything non-default, you should consult the new docstring.

| Old           | New                    |
| :-----------: | :--------------------: |
| `GitHubPages` | `Documenter{TravisCI}` |
| `GitLabPages` | `Documenter{GitLabCI}` |

## Package Generation

One less name to remember!

| Old                                         | New                                 |
| :-----------------------------------------: | :---------------------------------: |
| `generate(::Template, pkg::AbstractString)` | `(::Template)(pkg::AbstractString)` |

## Interactive Mode

| Old                                         | New                                 |
| :-----------------------------------------: | :---------------------------------: |
| `interactive_template()`                    | `Template(; interactive=true)`      |
| `generate_interactive(pkg::AbstractString)` | `Template(; interactive=true)(pkg)` |

## Other Functions

Two less names to remember!
Although it's unlikely that anyone used these.

| Old                  | New                                                                                                  |
| :------------------: | :--------------------------------------------------------------------------------------------------: |
| `available_licenses` | [View licenses on GitHub](https://github.com/JuliaCI/PkgTemplates.jl/tree/master/templates/licenses) |
| `show_license`       | [View licenses on GitHub](https://github.com/JuliaCI/PkgTemplates.jl/tree/master/templates/licenses) |

## Custom Plugins

In addition to the changes in usage, custom plugins from older versions of PkgTemplates will not work in 0.7+.
See the [Developer Guide](developer.md) for more information on the new extension API.
