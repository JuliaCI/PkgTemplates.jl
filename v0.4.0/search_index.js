var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#PkgTemplates-1",
    "page": "Home",
    "title": "PkgTemplates",
    "category": "section",
    "text": "(Image: Stable) (Image: Latest) (Image: Build Status) (Image: Build Status) (Image: Codecov)PkgTemplates is a Julia package for creating new Julia packages in an easy, repeatable, and customizable way."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "(v1.0) pkg> add PkgTemplates"
},

{
    "location": "index.html#Usage-1",
    "page": "Home",
    "title": "Usage",
    "category": "section",
    "text": "The simplest template requires no arguments.using PkgTemplates\nt = Template()\ngenerate(\"MyPkg\", t)\nrun(`git -C $(joinpath(t.dir, \"MyPkg\")) ls-files`);However, we can also configure a number of keyword arguments to Template:using PkgTemplates\nt = Template(;\n    user=\"myusername\",\n    license=\"MIT\",\n    authors=[\"Chris de Graaf\", \"Invenia Technical Computing Corporation\"],\n    dir=joinpath(homedir(), \"code\"),\n    julia_version=v\"0.7\",\n    ssh=true,\n    plugins=[\n        TravisCI(),\n        Codecov(),\n        Coveralls(),\n        AppVeyor(),\n        GitHubPages(),\n    ],\n)\ngenerate(\"MyPkg2\", t)\nrun(`git -C $(joinpath(t.dir, \"MyPkg2\")) ls-files`);If that looks like a lot of work, you can also create templates interactively with interactive_template:(Image: asciicast)And if that\'s still too much work for you, you can call interactive_template with fast=true to use default values for everything but username and plugin selection.You can also use generate_interactive to interactively generate a template and then immediately use it to create a new package."
},

{
    "location": "index.html#Comparison-to-PkgDev-1",
    "page": "Home",
    "title": "Comparison to PkgDev",
    "category": "section",
    "text": "PkgTemplates is similar in functionality to PkgDev\'s generate function. However, PkgTemplates offers more customizability in templates and more extensibility via plugins. For the package registration and release management features that PkgTemplates doesn\'t include, you are encouraged to use AttoBot instead."
},

{
    "location": "index.html#Contributing-1",
    "page": "Home",
    "title": "Contributing",
    "category": "section",
    "text": "It\'s extremely easy to extend PkgTemplates with new plugins. To get started, check out the plugin development guide."
},

{
    "location": "pages/package_generation.html#",
    "page": "Package Generation",
    "title": "Package Generation",
    "category": "page",
    "text": "CurrentModule = PkgTemplates"
},

{
    "location": "pages/package_generation.html#Package-Generation-1",
    "page": "Package Generation",
    "title": "Package Generation",
    "category": "section",
    "text": "Creating new packages with PkgTemplates revolves around creating a new Template, then calling generate on it."
},

{
    "location": "pages/package_generation.html#PkgTemplates.Template",
    "page": "Package Generation",
    "title": "PkgTemplates.Template",
    "category": "type",
    "text": "Template(; kwargs...) -> Template\n\nRecords common information used to generate a package. If you don\'t wish to manually create a template, you can use interactive_template instead.\n\nKeyword Arguments\n\nuser::AbstractString=\"\": GitHub (or other code hosting service) username. If left unset, it will take the the global git config\'s value (github.user). If that is not set, an ArgumentError is thrown. This is case-sensitive for some plugins, so take care to enter it correctly.\nhost::AbstractString=\"github.com\": URL to the code hosting service where your package will reside. Note that while hosts other than GitHub won\'t cause errors, they are not officially supported and they will cause certain plugins will produce incorrect output.\nlicense::AbstractString=\"MIT\": Name of the package license. If an empty string is given, no license is created. available_licenses can be used to list all available licenses, and show_license can be used to print out a particular license\'s text.\nauthors::Union{AbstractString, Vector{<:AbstractString}}=\"\": Names that appear on the license. Supply a string for one author or an array for multiple. Similarly to user, it will take the value of of the global git config\'s value if it is left unset.\ndir::AbstractString=~/.julia/dev: Directory in which the package will go. Relative paths are converted to absolute ones at template creation time.\njulia_version::VersionNumber=1.0.2: Minimum allowed Julia version.\nssh::Bool=false: Whether or not to use SSH for the remote.\nmanifest::Bool=false: Whether or not to commit the Manifest.toml.\nplugins::Vector{<:Plugin}=Plugin[]: A list of Plugins that the package will include.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.interactive_template",
    "page": "Package Generation",
    "title": "PkgTemplates.interactive_template",
    "category": "function",
    "text": "interactive_template(; fast::Bool=false) -> Template\n\nInteractively create a Template. If fast is set, defaults will be assumed for all values except username and plugins.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#Template-1",
    "page": "Package Generation",
    "title": "Template",
    "category": "section",
    "text": "Template\ninteractive_template"
},

{
    "location": "pages/package_generation.html#PkgTemplates.generate",
    "page": "Package Generation",
    "title": "PkgTemplates.generate",
    "category": "function",
    "text": "generate(pkg::AbstractString, t::Template) -> Nothing\ngenerate(t::Template, pkg::AbstractString) -> Nothing\n\nGenerate a package named pkg from t. If git is false, no Git repository is created.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.generate_interactive",
    "page": "Package Generation",
    "title": "PkgTemplates.generate_interactive",
    "category": "function",
    "text": "generate_interactive(pkg::AbstractString; fast::Bool=false, git::Bool=true) -> Template\n\nInteractively create a template, and then generate a package with it. Arguments and keywords are used in the same way as in generate and interactive_template.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#generate-1",
    "page": "Package Generation",
    "title": "generate",
    "category": "section",
    "text": "generate\ngenerate_interactive"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_tests",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_tests",
    "category": "function",
    "text": "gen_tests(pkg_dir::AbstractString, t::Template) -> Vector{String}\n\nCreate the test entrypoint in pkg_dir.\n\nArguments\n\npkg_dir::AbstractString: The package directory in which the files will be generated\nt::Template: The template whose tests we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_require",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_require",
    "category": "function",
    "text": "gen_require(pkg_dir::AbstractString, t::Template) -> Vector{String}\n\nCreate the REQUIRE file in pkg_dir.\n\nArguments\n\npkg_dir::AbstractString: The directory in which the files will be generated.\nt::Template: The template whose REQUIRE we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_readme",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_readme",
    "category": "function",
    "text": "gen_readme(pkg_dir::AbstractString, t::Template) -> Vector{String}\n\nCreate a README in pkg_dir with badges for each enabled plugin.\n\nArguments\n\npkg_dir::AbstractString: The directory in which the files will be generated.\nt::Template: The template whose README we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_gitignore",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_gitignore",
    "category": "function",
    "text": "gen_gitignore(pkg_dir::AbstractString, t::Template) -> Vector{String}\n\nCreate a .gitignore in pkg_dir.\n\nArguments\n\npkg_dir::AbstractString: The directory in which the files will be generated.\nt::Template: The template whose .gitignore we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_license",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_license",
    "category": "function",
    "text": "gen_license(pkg_dir::AbstractString, t::Template) -> Vector{String}\n\nCreate a license in pkg_dir.\n\nArguments\n\npkg_dir::AbstractString: The directory in which the files will be generated.\nt::Template: The template whose LICENSE we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/package_generation.html#Helper-Functions-1",
    "page": "Package Generation",
    "title": "Helper Functions",
    "category": "section",
    "text": "gen_tests\ngen_require\ngen_readme\ngen_gitignore\ngen_license"
},

{
    "location": "pages/plugins.html#",
    "page": "Plugins",
    "title": "Plugins",
    "category": "page",
    "text": "CurrentModule = PkgTemplates"
},

{
    "location": "pages/plugins.html#Plugins-1",
    "page": "Plugins",
    "title": "Plugins",
    "category": "section",
    "text": "Plugins are the secret sauce behind PkgTemplates\'s customization and extension. This page describes plugins that already exist; for information on writing your own plugins, see Plugin Development."
},

{
    "location": "pages/plugins.html#PkgTemplates.TravisCI",
    "page": "Plugins",
    "title": "PkgTemplates.TravisCI",
    "category": "type",
    "text": "TravisCI(; config_file::Union{AbstractString, Nothing}=\"\") -> TravisCI\n\nAdd TravisCI to a template\'s plugins to add a .travis.yml configuration file to generated repositories, and an appropriate badge to the README.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Nothing}=\"\": Path to a custom .travis.yml. If nothing is supplied, no file will be generated.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#PkgTemplates.AppVeyor",
    "page": "Plugins",
    "title": "PkgTemplates.AppVeyor",
    "category": "type",
    "text": "AppVeyor(; config_file::Union{AbstractString, Nothing}=\"\") -> AppVeyor\n\nAdd AppVeyor to a template\'s plugins to add a .appveyor.yml configuration file to generated repositories, and an appropriate badge to the README.\n\nKeyword Arguments\n\nconfig_file::Union{AbstractString, Nothing}=\"\": Path to a custom .appveyor.yml. If nothing is supplied, no file will be generated.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#PkgTemplates.GitLabCI",
    "page": "Plugins",
    "title": "PkgTemplates.GitLabCI",
    "category": "type",
    "text": "GitLabCI(; config_file::Union{AbstractString, Nothing}=\"\", coverage::Bool=true) -> GitLabCI\n\nAdd GitLabCI to a template\'s plugins to add a .gitlab-ci.yml configuration file to generated repositories, and appropriate badge(s) to the README.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Nothing}=\"\": Path to a custom .gitlab-ci.yml. If nothing is supplied, no file will be generated.\ncoverage::Bool=true: Whether or not GitLab CI\'s built-in code coverage analysis should be enabled.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#Continuous-Integration-(CI)-1",
    "page": "Plugins",
    "title": "Continuous Integration (CI)",
    "category": "section",
    "text": "TravisCI\nAppVeyor\nGitLabCI"
},

{
    "location": "pages/plugins.html#PkgTemplates.Codecov",
    "page": "Plugins",
    "title": "PkgTemplates.Codecov",
    "category": "type",
    "text": "Codecov(; config_file::Union{AbstractString, Nothing}=nothing) -> Codecov\n\nAdd Codecov to a template\'s plugins to optionally add a .codecov.yml configuration file to generated repositories, and an appropriate badge to the README. Also updates the .gitignore accordingly.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Nothing}=nothing: Path to a custom .codecov.yml. If left unset, no file will be generated.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#PkgTemplates.Coveralls",
    "page": "Plugins",
    "title": "PkgTemplates.Coveralls",
    "category": "type",
    "text": "Coveralls(; config_file::Union{AbstractString, Nothing}=nothing) -> Coveralls\n\nAdd Coveralls to a template\'s plugins to optionally add a .coveralls.yml configuration file to generated repositories, and an appropriate badge to the README. Also updates the .gitignore accordingly.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Nothing}=nothing: Path to a custom .coveralls.yml. If left unset, no file will be generated.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#Code-Coverage-1",
    "page": "Plugins",
    "title": "Code Coverage",
    "category": "section",
    "text": "Codecov\nCoveralls"
},

{
    "location": "pages/plugins.html#PkgTemplates.Documenter",
    "page": "Plugins",
    "title": "PkgTemplates.Documenter",
    "category": "type",
    "text": "Add a Documenter subtype to a template\'s plugins to add support for documentation generation via Documenter.jl.\n\nBy default, the plugin generates a minimal index.md and a make.jl file. The make.jl file contains the Documenter.makedocs command with predefined values for modules, format, pages, repo, sitename, and authors.\n\nThe subtype is expected to include the following fields:\n\nassets::Vector{AbstractString}, a list of filenames to be included as the assets\n\nkwarg to makedocs\n\ngitignore::Vector{AbstractString}, a list of files to be added to the .gitignore\n\nIt may optionally include the field additional_kwargs::Union{AbstractDict, NamedTuple} to allow additional kwargs to be added to makedocs.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#PkgTemplates.GitHubPages",
    "page": "Plugins",
    "title": "PkgTemplates.GitHubPages",
    "category": "type",
    "text": "GitHubPages(; assets::Vector{<:AbstractString}=String[]) -> GitHubPages\n\nAdd GitHubPages to a template\'s plugins to add Documenter support via GitHub Pages, including automatic uploading of documentation from TravisCI. Also adds appropriate badges to the README, and updates the .gitignore accordingly.\n\nKeyword Arguments\n\nassets::Vector{<:AbstractString}=String[]: Array of paths to Documenter asset files.\n\n\n\n\n\n"
},

{
    "location": "pages/plugins.html#Documentation-1",
    "page": "Plugins",
    "title": "Documentation",
    "category": "section",
    "text": "Documenter\nGitHubPages"
},

{
    "location": "pages/plugin_development.html#",
    "page": "Plugin Development",
    "title": "Plugin Development",
    "category": "page",
    "text": "CurrentModule = PkgTemplates"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.Plugin",
    "page": "Plugin Development",
    "title": "PkgTemplates.Plugin",
    "category": "type",
    "text": "A plugin to be added to a Template, which adds some functionality or integration. New plugins should almost always extend GenericPlugin or CustomPlugin.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#Plugin-Development-1",
    "page": "Plugin Development",
    "title": "Plugin Development",
    "category": "section",
    "text": "The best and easiest way to contribute to PkgTemplates is to write new plugins.Plugin"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.GenericPlugin",
    "page": "Plugin Development",
    "title": "PkgTemplates.GenericPlugin",
    "category": "type",
    "text": "Generic plugins are plugins that add any number of patterns to the generated package\'s .gitignore, and have at most one associated file to generate.\n\nAttributes\n\ngitignore::Vector{AbstractString}: Array of patterns to be added to the .gitignore of generated packages that use this plugin.\nsrc::Union{AbstractString, Nothing}: Path to the file that will be copied into the generated package repository. If set to nothing, no file will be generated. When this defaults to an empty string, there should be a default file in defaults that will be copied. That file\'s name is usually the same as the plugin\'s name, except in all lowercase and with the .yml extension. If this is not the case, an interactive method needs to be implemented to call interactive(; file=\"file.ext\").\ndest::AbstractString: Path to the generated file, relative to the root of the generated package repository.\nbadges::Vector{Badge}: Array of Badges containing information used to create Markdown-formatted badges from the plugin. Entries will be run through substitute, so they may contain placeholder values.\nview::Dict{String, Any}: Additional substitutions to make in both the plugin\'s badges and its associated file. See substitute for details.\n\nExample\n\n@auto_hash_equals struct MyPlugin <: GenericPlugin\n    gitignore::Vector{AbstractString}\n    src::Union{AbstractString, Nothing}\n    dest::AbstractString\n    badges::Vector{Badge}\n    view::Dict{String, Any}\n\n    function MyPlugin(; config_file::Union{AbstractString, Nothing}=\"\")\n        if config_file != nothing\n            config_file = if isempty(config_file)\n                joinpath(DEFAULTS_DIR, \"my-plugin.toml\")\n            elseif isfile(config_file)\n                abspath(config_file)\n            else\n                throw(ArgumentError(\n                    \"File $(abspath(config_file)) does not exist\"\n                ))\n            end\n        end\n        new(\n            [\"*.mgp\"],\n            config_file,\n            \".my-plugin.toml\",\n            [\n                Badge(\n                    \"My Plugin\",\n                    \"https://myplugin.com/badge-{{YEAR}}.png\",\n                    \"https://myplugin.com/{{USER}}/{{PKGNAME}}.jl\",\n                ),\n            ],\n            Dict{String, Any}(\"YEAR\" => year(today())),\n        )\n    end\nend\n\ninteractive(::Type{MyPlugin}) = interactive(MyPlugin; file=\"my-plugin.toml\")\n\nThe above plugin ignores files ending with .mgp, copies defaults/my-plugin.toml by default, and creates a badge that links to the project on its own site, using the default substitutions with one addition: {{YEAR}} => year(today()). Since the default config template file doesn\'t follow the generic naming convention, we added another interactive method to correct the assumed filename.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#Generic-Plugins-1",
    "page": "Plugin Development",
    "title": "Generic Plugins",
    "category": "section",
    "text": "GenericPlugin"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.CustomPlugin",
    "page": "Plugin Development",
    "title": "PkgTemplates.CustomPlugin",
    "category": "type",
    "text": "Custom plugins are plugins whose behaviour does not follow the GenericPlugin pattern. They can implement gen_plugin, badges, and interactive in any way they choose, as long as they conform to the usual type signature.\n\nAttributes\n\ngitignore::Vector{AbstractString}: Array of patterns to be added to the .gitignore of generated packages that use this plugin.\n\nExample\n\n@auto_hash_equals struct MyPlugin <: CustomPlugin\n    gitignore::Vector{AbstractString}\n    lucky::Bool\n\n    MyPlugin() = new([], rand() > 0.8)\n\n    function gen_plugin(p::MyPlugin, t::Template, pkg_name::AbstractString)\n        return if p.lucky\n            text = substitute(\"You got lucky with {{PKGNAME}}, {{USER}}!\", t)\n            gen_file(joinpath(t.dir, pkg_name, \".myplugin.yml\"), text)\n            [\".myplugin.yml\"]\n        else\n            println(\"Maybe next time.\")\n            String[]\n        end\n    end\n\n    function badges(p::MyPlugin, user::AbstractString, pkg_name::AbstractString)\n        return if p.lucky\n            [\n                format(Badge(\n                    \"You got lucky!\",\n                    \"https://myplugin.com/badge.png\",\n                    \"https://myplugin.com/$user/$pkg_name.jl\",\n                )),\n            ]\n        else\n            String[]\n        end\n    end\nend\n\ninteractive(:Type{MyPlugin}) = MyPlugin()\n\nThis plugin doesn\'t do much, but it demonstrates how gen_plugin, badges and interactive can be implemented using substitute, gen_file, Badge, and format.\n\nDefining Template Files\n\nOften, the contents of the config file that your plugin generates depends on variables like the package name, the user\'s username, etc. Template files (which are stored in defaults) can use here\'s syntax to define replacements.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#Custom-Plugins-1",
    "page": "Plugin Development",
    "title": "Custom Plugins",
    "category": "section",
    "text": "CustomPlugin"
},

{
    "location": "pages/plugin_development.html#CustomPlugin-Required-Methods-1",
    "page": "Plugin Development",
    "title": "CustomPlugin Required Methods",
    "category": "section",
    "text": ""
},

{
    "location": "pages/plugin_development.html#PkgTemplates.gen_plugin",
    "page": "Plugin Development",
    "title": "PkgTemplates.gen_plugin",
    "category": "function",
    "text": "gen_plugin(p::Plugin, t::Template, pkg_name::AbstractString) -> Vector{String}\n\nGenerate any files associated with a plugin.\n\nArguments\n\np::Plugin: Plugin whose files are being generated.\nt::Template: Template configuration.\npkg_name::AbstractString: Name of the package.\n\nReturns an array of generated file/directory names.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.interactive",
    "page": "Plugin Development",
    "title": "PkgTemplates.interactive",
    "category": "function",
    "text": "interactive(T::Type{<:Plugin}; file::Union{AbstractString, Nothing}=\"\") -> Plugin\n\nInteractively create a plugin of type T, where file is the plugin type\'s default config template with a non-standard name (for MyPlugin, this is anything but \"myplugin.yml\").\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#gen_plugin-1",
    "page": "Plugin Development",
    "title": "gen_plugin",
    "category": "section",
    "text": "gen_plugin\ninteractiveNote: interactive is not strictly required, however without it, your custom plugin will not be available when creating templates with interactive_template."
},

{
    "location": "pages/plugin_development.html#PkgTemplates.badges",
    "page": "Plugin Development",
    "title": "PkgTemplates.badges",
    "category": "function",
    "text": "badges(p::Plugin, user::AbstractString, pkg_name::AbstractString) -> Vector{String}\n\nGenerate Markdown badges for the plugin.\n\nArguments\n\np::Plugin: Plugin whose badges we are generating.\nuser::AbstractString: Username of the package creator.\npkg_name::AbstractString: Name of the package.\n\nReturns an array of Markdown badges.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#badges-1",
    "page": "Plugin Development",
    "title": "badges",
    "category": "section",
    "text": "badges"
},

{
    "location": "pages/plugin_development.html#Helper-Types/Functions-1",
    "page": "Plugin Development",
    "title": "Helper Types/Functions",
    "category": "section",
    "text": ""
},

{
    "location": "pages/plugin_development.html#PkgTemplates.gen_file",
    "page": "Plugin Development",
    "title": "PkgTemplates.gen_file",
    "category": "function",
    "text": "gen_file(file::AbstractString, text::AbstractString) -> Int\n\nCreate a new file containing some given text. Always ends the file with a newline.\n\nArguments\n\nfile::AbstractString: Path to the file to be created.\ntext::AbstractString: Text to write to the file.\n\nReturns the number of bytes written to the file.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#gen_file-1",
    "page": "Plugin Development",
    "title": "gen_file",
    "category": "section",
    "text": "gen_file"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.substitute",
    "page": "Plugin Development",
    "title": "PkgTemplates.substitute",
    "category": "function",
    "text": "substitute(template::AbstractString, view::Dict{String, Any}) -> String\nsubstitute(\n    template::AbstractString,\n    pkg_template::Template;\n    view::Dict{String, Any}=Dict{String, Any}(),\n) -> String\n\nReplace placeholders in template with values in view via Mustache. template is not modified. If pkg_template is supplied, some default replacements are also performed.\n\nFor information on how to structure template, see \"Defining Template Files\" section in Custom Plugins.\n\nNote: Conditionals in template without a corresponding key in view won\'t error, but will simply be evaluated as false.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#substitute-1",
    "page": "Plugin Development",
    "title": "substitute",
    "category": "section",
    "text": "substitute"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.Badge",
    "page": "Plugin Development",
    "title": "PkgTemplates.Badge",
    "category": "type",
    "text": "Badge(hover::AbstractString, image::AbstractString, link::AbstractString) -> Badge\n\nA Badge contains the data necessary to generate a Markdown badge.\n\nArguments\n\nhover::AbstractString: Text to appear when the mouse is hovered over the badge.\nimage::AbstractString: URL to the image to display.\nlink::AbstractString: URL to go to upon clicking the badge.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#Badge-1",
    "page": "Plugin Development",
    "title": "Badge",
    "category": "section",
    "text": "Badge"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.format",
    "page": "Plugin Development",
    "title": "PkgTemplates.format",
    "category": "function",
    "text": "format(b::Badge) -> String\n\nReturn badge\'s data formatted as a Markdown string.\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#format-1",
    "page": "Plugin Development",
    "title": "format",
    "category": "section",
    "text": "format"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.version_floor",
    "page": "Plugin Development",
    "title": "PkgTemplates.version_floor",
    "category": "function",
    "text": "version_floor(v::VersionNumber=VERSION) -> String\n\nFormat the given Julia version.\n\nKeyword arguments\n\nv::VersionNumber=VERSION: Version to floor.\n\nReturns \"major.minor\" for the most recent release version relative to v. For prereleases with v.minor == v.patch == 0, returns \"major.minor-\".\n\n\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#version_floor-1",
    "page": "Plugin Development",
    "title": "version_floor",
    "category": "section",
    "text": "version_floor"
},

{
    "location": "pages/licenses.html#",
    "page": "Licenses",
    "title": "Licenses",
    "category": "page",
    "text": "CurrentModule = PkgTemplates"
},

{
    "location": "pages/licenses.html#PkgTemplates.available_licenses",
    "page": "Licenses",
    "title": "PkgTemplates.available_licenses",
    "category": "function",
    "text": "available_licenses([io::IO]) -> Nothing\n\nPrint the names of all available licenses.\n\n\n\n\n\n"
},

{
    "location": "pages/licenses.html#PkgTemplates.show_license",
    "page": "Licenses",
    "title": "PkgTemplates.show_license",
    "category": "function",
    "text": "show_license([io::IO], license::AbstractString) -> Nothing\n\nPrint the text of license. Errors if the license is not found.\n\n\n\n\n\n"
},

{
    "location": "pages/licenses.html#Licenses-1",
    "page": "Licenses",
    "title": "Licenses",
    "category": "section",
    "text": "Many open-source licenses are available for use with PkgTemplates, but if you see that one is missing, don\'t hesitate to open an issue or PR.available_licenses\nshow_license"
},

{
    "location": "pages/licenses.html#PkgTemplates.read_license",
    "page": "Licenses",
    "title": "PkgTemplates.read_license",
    "category": "function",
    "text": "read_license(license::AbstractString) -> String\n\nReturns the contents of license. Errors if the license is not found. Use available_licenses to view available licenses.\n\n\n\n\n\n"
},

{
    "location": "pages/licenses.html#Helper-Functions-1",
    "page": "Licenses",
    "title": "Helper Functions",
    "category": "section",
    "text": "read_license"
},

{
    "location": "pages/index.html#",
    "page": "Index",
    "title": "Index",
    "category": "page",
    "text": ""
},

{
    "location": "pages/index.html#Index-1",
    "page": "Index",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
