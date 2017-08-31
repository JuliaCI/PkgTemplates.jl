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
    "text": "(Image: Stable) (Image: Latest) (Image: Build Status) (Image: Build Status) (Image: CodeCov)PkgTemplates is a Julia package for creating new Julia packages in an easy, repeatable, and customizable way."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "PkgTemplates is registered in METADATA.jl, so run Pkg.add(\"PkgTemplates\") for the latest release, or Pkg.clone(\"PkgTemplates\") for the development version."
},

{
    "location": "index.html#Usage-1",
    "page": "Home",
    "title": "Usage",
    "category": "section",
    "text": "The simplest template only requires your GitHub username.using PkgTemplates\nt = Template(; user=\"myusername\")\ngenerate(\"MyPkg\", t)\ncd(joinpath(t.dir, \"MyPkg\")); run(`git ls-tree -r --name-only HEAD`)However, we can also configure a number of keyword arguments to Template and generate:using PkgTemplates\nt = Template(;\n    user=\"myusername\",\n    license=\"MIT\",\n    authors=[\"Chris de Graaf\", \"Invenia Technical Computing Corporation\"],\n    years=\"2016-2017\",\n    dir=joinpath(homedir(), \"code\"),\n    julia_version=v\"0.5.2\",\n    requirements=[\"PkgTemplates\"],\n    gitconfig=Dict(\"diff.renames\" => true),\n    plugins=[\n        TravisCI(),\n        CodeCov(; config_file=nothing),\n        Coveralls(),\n        AppVeyor(),\n        GitHubPages(),\n    ],\n)\ngenerate(\"MyPkg\", t; force=true, ssh=true)\ncd(joinpath(t.dir, \"MyPkg\")); run(`git ls-tree -r --name-only HEAD`)If that looks like a lot of work, you can also create templates interactively with interactive_template:(Image: asciicast)And if that's still too much work for you, you can call interactive_template with fast=true to use default values for everything but username and plugin selection."
},

{
    "location": "index.html#Comparison-to-[PkgDev](https://github.com/JuliaLang/PkgDev.jl)-1",
    "page": "Home",
    "title": "Comparison to PkgDev",
    "category": "section",
    "text": "PkgTemplates is similar in functionality to PkgDev's generate function. However, PkgTemplates offers more customizability in templates and more extensibility via plugins. For the package registration and release management features that PkgTemplates lacks, you are encouraged to use AttoBot instead."
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
    "category": "Type",
    "text": "Template(; kwargs...) -> Template\n\nRecords common information used to generate a package. If you don't wish to manually create a template, you can use interactive_template instead.\n\nKeyword Arguments\n\nuser::AbstractString=\"\": GitHub username. If left  unset, it will try to take the value of a supplied git config's \"github.user\" key, then the global git config's value. If neither is set, an ArgumentError is thrown. This is case-sensitive for some plugins, so take care to enter it correctly.\nhost::AbstractString=\"github.com\": URL to the code hosting service where your package will reside. Note that while hosts other than GitHub won't cause errors, they are not officially supported and they will cause certain plugins will produce incorrect output. For example, AppVeyor's badge image will point to a GitHub-specific URL, regardless of the value of host.\nlicense::AbstractString=\"MIT\": Name of the package license. If an empty string is given, no license is created. available_licenses can be used to list all available licenses, and show_license can be used to print out a particular license's text.\nauthors::Union{AbstractString, Vector{<:AbstractString}}=\"\": Names that appear on the license. Supply a string for one author or an array for multiple. Similarly to user, it will try to take the value of a supplied git config's \"user.name\" key, then the global git config's value, if it is left unset.\nyears::Union{Integer, AbstractString}=Dates.year(Dates.today()): Copyright years on the license. Can be supplied by a number, or a string such as \"2016 - 2017\".\ndir::AbstractString=Pkg.dir(): Directory in which the package will go. Relative paths are converted to absolute ones at template creation time.\njulia_version::VersionNumber=VERSION: Minimum allowed Julia version.\nrequirements::Vector{<:AbstractString}=String[]: Package requirements. If there are duplicate requirements with different versions, i.e. [\"PkgTemplates\", \"PkgTemplates 0.1\"], an ArgumentError is thrown. Each entry in this array will be copied into the REQUIRE file of packages generated with this template.\ngitconfig::Dict=Dict(): Git configuration options.\nplugins::Vector{<:Plugin}=Plugin[]: A list of Plugins that the package will include.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#PkgTemplates.interactive_template",
    "page": "Package Generation",
    "title": "PkgTemplates.interactive_template",
    "category": "Function",
    "text": "interactive_template(; fast::Bool=false) -> Template\n\nInteractively create a Template. If fast is set, defaults will be assumed for all values except username and plugins.\n\n\n\n"
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
    "category": "Function",
    "text": "generate(\n    pkg_name::AbstractString,\n    t::Template;\n    force::Bool=false,\n    ssh::Bool=false,\n) -> Void\n\nGenerate a package names pkg_name from template.\n\nKeyword Arguments\n\nforce::Bool=false: Whether or not to overwrite old packages with the same name.\nssh::Bool=false: Whether or not to use SSH for the remote.\n\nNotes\n\nThe package is generated entirely in a temporary directory and only moved into joinpath(t.dir, pkg_name) at the very end. In the case of an error, the temporary directory will contain leftovers, but the destination directory will remain untouched (this is especially helpful when force=true).\n\n\n\n"
},

{
    "location": "pages/package_generation.html#generate-1",
    "page": "Package Generation",
    "title": "generate",
    "category": "section",
    "text": "generate"
},

{
    "location": "pages/package_generation.html#Helper-Functions-1",
    "page": "Package Generation",
    "title": "Helper Functions",
    "category": "section",
    "text": ""
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_entrypoint",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_entrypoint",
    "category": "Function",
    "text": "gen_entrypoint(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate the module entrypoint in the temp package directory.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose entrypoint we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_entrypoint-1",
    "page": "Package Generation",
    "title": "gen_entrypoint",
    "category": "section",
    "text": "gen_entrypoint"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_tests",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_tests",
    "category": "Function",
    "text": "gen_tests(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate the test directory and entrypoint in the temp package directory.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose tests we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_tests-1",
    "page": "Package Generation",
    "title": "gen_tests",
    "category": "section",
    "text": "gen_tests"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_require",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_require",
    "category": "Function",
    "text": "gen_require(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate the REQUIRE file in the temp package directory.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose REQUIRE we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_require-1",
    "page": "Package Generation",
    "title": "gen_require",
    "category": "section",
    "text": "gen_require"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_readme",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_readme",
    "category": "Function",
    "text": "gen_readme(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate a README in the temp package directory with badges for each enabled plugin.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose README we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_readme-1",
    "page": "Package Generation",
    "title": "gen_readme",
    "category": "section",
    "text": "gen_readme"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_gitignore",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_gitignore",
    "category": "Function",
    "text": "gen_gitignore(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate a .gitignore in the temp package directory.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose .gitignore we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_gitignore-1",
    "page": "Package Generation",
    "title": "gen_gitignore",
    "category": "section",
    "text": "gen_gitignore"
},

{
    "location": "pages/package_generation.html#PkgTemplates.gen_license",
    "page": "Package Generation",
    "title": "PkgTemplates.gen_license",
    "category": "Function",
    "text": "gen_license(\n    dir::AbstractString,\n    pkg_name::AbstractString,\n    template::Template,\n) -> Vector{String}\n\nCreate a license in the temp package directory.\n\nArguments\n\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\ntemplate::Template: The template whose LICENSE we are generating.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/package_generation.html#gen_license-1",
    "page": "Package Generation",
    "title": "gen_license",
    "category": "section",
    "text": "gen_license"
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
    "text": "Plugins are the driver for PkgTemplates's customization and extension. This page describes plugins that already exist; for information on writing your own plugins, see Plugin Development."
},

{
    "location": "pages/plugins.html#PkgTemplates.TravisCI",
    "page": "Plugins",
    "title": "PkgTemplates.TravisCI",
    "category": "Type",
    "text": "TravisCI(; config_file::Union{AbstractString, Void}=\"\") -> TravisCI\n\nAdd TravisCI to a template's plugins to add a .travis.yml configuration file to generated repositories, and an appropriate badge to the README.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Void}=\"\": Path to a custom .travis.yml. If nothing is supplied, no file will be generated.\n\n\n\n"
},

{
    "location": "pages/plugins.html#TravisCI-1",
    "page": "Plugins",
    "title": "TravisCI",
    "category": "section",
    "text": "TravisCI"
},

{
    "location": "pages/plugins.html#PkgTemplates.AppVeyor",
    "page": "Plugins",
    "title": "PkgTemplates.AppVeyor",
    "category": "Type",
    "text": "AppVeyor(; config_file::Union{AbstractString, Void}=\"\") -> AppVeyor\n\nAdd AppVeyor to a template's plugins to add a .appveyor.yml configuration file to generated repositories, and an appropriate badge to the README.\n\nKeyword Arguments\n\nconfig_file::Union{AbstractString, Void}=\"\": Path to a custom .appveyor.yml. If nothing is supplied, no file will be generated.\n\n\n\n"
},

{
    "location": "pages/plugins.html#AppVeyor-1",
    "page": "Plugins",
    "title": "AppVeyor",
    "category": "section",
    "text": "AppVeyor"
},

{
    "location": "pages/plugins.html#PkgTemplates.CodeCov",
    "page": "Plugins",
    "title": "PkgTemplates.CodeCov",
    "category": "Type",
    "text": "CodeCov(; config_file::Union{AbstractString, Void}=\"\") -> CodeCov\n\nAdd CodeCov to a template's plugins to add a .codecov.yml configuration file to generated repositories, and an appropriate badge to the README. Also updates the .gitignore accordingly.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Void}=\"\": Path to a custom .codecov.yml. If nothing is supplied, no file will be generated.\n\n\n\n"
},

{
    "location": "pages/plugins.html#CodeCov-1",
    "page": "Plugins",
    "title": "CodeCov",
    "category": "section",
    "text": "CodeCov"
},

{
    "location": "pages/plugins.html#PkgTemplates.Coveralls",
    "page": "Plugins",
    "title": "PkgTemplates.Coveralls",
    "category": "Type",
    "text": "Coveralls(; config_file::Union{AbstractString, Void}=\"\") -> Coveralls\n\nAdd Coveralls to a template's plugins to optionally add a .coveralls.yml configuration file to generated repositories, and an appropriate badge to the README. Also updates the .gitignore accordingly.\n\nKeyword Arguments:\n\nconfig_file::Union{AbstractString, Void}=nothing: Path to a custom .coveralls.yml. If left unset, no file will be generated.\n\n\n\n"
},

{
    "location": "pages/plugins.html#Coveralls-1",
    "page": "Plugins",
    "title": "Coveralls",
    "category": "section",
    "text": "Coveralls"
},

{
    "location": "pages/plugins.html#PkgTemplates.Documenter",
    "page": "Plugins",
    "title": "PkgTemplates.Documenter",
    "category": "Type",
    "text": "Add a Documenter subtype to a template's plugins to add support for documentation generation via Documenter.jl.\n\n\n\n"
},

{
    "location": "pages/plugins.html#Documenter-1",
    "page": "Plugins",
    "title": "Documenter",
    "category": "section",
    "text": "Documenter"
},

{
    "location": "pages/plugins.html#PkgTemplates.GitHubPages",
    "page": "Plugins",
    "title": "PkgTemplates.GitHubPages",
    "category": "Type",
    "text": "GitHubPages(; assets::Vector{<:AbstractString}=String[]) -> GitHubPages\n\nAdd GitHubPages to a template's plugins to add Documenter support via GitHub Pages, including automatic uploading of documentation from TravisCI. Also adds appropriate badges to the README, and updates the .gitignore accordingly.\n\nKeyword Arguments\n\nassets::Vector{String}=String[]: Array of paths to Documenter asset files.\n\n\n\n"
},

{
    "location": "pages/plugins.html#GitHubPages-1",
    "page": "Plugins",
    "title": "GitHubPages",
    "category": "section",
    "text": "GitHubPages"
},

{
    "location": "pages/plugin_development.html#",
    "page": "Plugin Development",
    "title": "Plugin Development",
    "category": "page",
    "text": "CurrentModule = PkgTemplates"
},

{
    "location": "pages/plugin_development.html#Plugin-Development-1",
    "page": "Plugin Development",
    "title": "Plugin Development",
    "category": "section",
    "text": "The best and easiest way to contribute to PkgTemplates is to write new plugins.There are two types of plugins: GenericPlugins and CustomPlugins."
},

{
    "location": "pages/plugin_development.html#PkgTemplates.GenericPlugin",
    "page": "Plugin Development",
    "title": "PkgTemplates.GenericPlugin",
    "category": "Type",
    "text": "Generic plugins are plugins that add any number of patterns to the generated package's .gitignore, and have at most one associated file to generate.\n\nAttributes\n\ngitignore::Vector{AbstractString}: Array of patterns to be added to the .gitignore of generated packages that use this plugin.\nsrc::Nullable{AbstractString}: Path to the file that will be copied into the generated package repository. If set to nothing, no file will be generated. When this defaults to an empty string, there should be a default file in defaults that will be copied. That file's name is usually the same as the plugin's name, except in all lowercase and with the .yml extension. If this is not the case, an interactive method needs to be implemented to call interactive(; file=\"file.ext\").\ndest::AbstractString: Path to the generated file, relative to the root of the generated package repository.\nbadges::Vector{Badge}: Array of Badges containing information used to create Markdown-formatted badges from the plugin. Entries will be run through substitute, so they may contain placeholder values.\nview::Dict{String, Any}: Additional substitutions to make in both the plugin's badges and its associated file. See substitute for details.\n\nExample\n\n@auto_hash_equals struct MyPlugin <: GenericPlugin\n    gitignore::Vector{AbstractString}\n    src::Nullable{AbstractString}\n    dest::AbstractString\n    badges::Vector{Badge}\n    view::Dict{String, Any}\n\n    function MyPlugin(; config_file::Union{AbstractString, Void}=\"\")\n        if config_file != nothing\n            if isempty(config_file)\n                config_file = joinpath(DEFAULTS_DIR, \"my-plugin.toml\")\n            elseif !isfile(config_file)\n                throw(ArgumentError(\n                    \"File $(abspath(config_file)) does not exist\"\n                ))\n            end\n        end\n        new(\n            [\"*.mgp\"],\n            config_file,\n            \".myplugin.yml\",\n            [\n                Badge(\n                    \"My Plugin\",\n                    \"https://myplugin.com/badge-{{YEAR}}.png\",\n                    \"https://myplugin.com/{{USER}}/{{PKGNAME}}.jl\",\n                ),\n            ],\n            Dict{String, Any}(\"YEAR\" => Dates.year(Dates.today())),\n        )\n    end\nend\n\ninteractive(plugin_type::Type{MyPlugin}) = interactive(plugin_type; file=\"my-plugin.toml\")\n\nThe above plugin ignores files ending with .mgp, copies defaults/my-plugin.toml by default, and creates a badge that links to the project on its own site, using the default substitutions with one addition: {{YEAR}} => Dates.year(Dates.today()). Since the default config template file doesn't follow the generic naming convention, we added another interactive method to correct the assumed filename.\n\n\n\n"
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
    "category": "Type",
    "text": "Custom plugins are plugins whose behaviour does not follow the GenericPlugin pattern. They can implement gen_plugin, badges, and interactive in any way they choose.\n\nAttributes\n\ngitignore::Vector{AbstractString}: Array of patterns to be added to the .gitignore of generated packages that use this plugin.\n\nExample\n\n@auto_hash_equals struct MyPlugin <: CustomPlugin\n    gitignore::Vector{AbstractString}\n    lucky::Bool\n\n    MyPlugin() = new([], rand() > 0.8)\n\n    function gen_plugin(\n        plugin::MyPlugin,\n        template::Template,\n        dir::AbstractString,\n        pkg_name::AbstractString\n    )\n        if plugin.lucky\n            text = substitute(\n                \"You got lucky with {{PKGNAME}}, {{USER}}!\",\n                template,\n            )\n            gen_file(joinpath(dir, \".myplugin.yml\"), text)\n        else\n            println(\"Maybe next time.\")\n        end\n    end\n\n    function badges(\n        plugin::MyPlugin,\n        user::AbstractString,\n        pkg_name::AbstractString,\n    )\n        if plugin.lucky\n            return [\n                format(Badge(\n                    \"You got lucky!\",\n                    \"https://myplugin.com/badge.png\",\n                    \"https://myplugin.com/$user/$pkg_name.jl\",\n                )),\n            ]\n        else\n            return String[]\n        end\n    end\nend\n\ninteractive(plugin_type::Type{MyPlugin}) = MyPlugin()\n\nThis plugin doesn't do much, but it demonstrates how gen_plugin, badges and interactive can be implemented using substitute, gen_file, Badge, and format.\n\nDefining Template Files\n\nOften, the contents of the config file that your plugin generates depends on variables like the package name, the user's username, etc. Template files (which are stored in defaults) can use here's syntax to define replacements.\n\nNote: Due to a bug in Mustache, conditionals can insert undesired newlines (more detail here).\n\n\n\n"
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
    "category": "Function",
    "text": "gen_plugin(\n    plugin::Plugin,\n    template::Template,\n    dir::AbstractString,\n    pkg_name::AbstractString\n) -> Vector{String}\n\nGenerate any files associated with a plugin.\n\nArguments\n\nplugin::Plugin: Plugin whose files are being generated.\ntemplate::Template: Template configuration.\ndir::AbstractString: The directory in which the files will be generated. Note that this will be joined to pkg_name.\npkg_name::AbstractString: Name of the package.\n\nReturns an array of generated file/directory names.\n\n\n\n"
},

{
    "location": "pages/plugin_development.html#PkgTemplates.interactive",
    "page": "Plugin Development",
    "title": "PkgTemplates.interactive",
    "category": "Function",
    "text": "interactive(\n    plugin_type::Type{P <: Plugin};\n    file::Union{AbstractString, Void}=\"\",\n) -> Plugin\n\nInteractively create a plugin of type plugin_type, where file is the plugin type's default config template with a non-standard name (for MyPlugin, this is anything but \"myplugin.yml\").\n\n\n\n"
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
    "category": "Function",
    "text": "badges(plugin::Plugin, user::AbstractString, pkg_name::AbstractString) -> Vector{String}\n\nGenerate Markdown badges for the plugin.\n\nArguments\n\nplugin::Plugin: Plugin whose badges we are generating.\nuser::AbstractString: Username of the package creator.\npkg_name::AbstractString: Name of the package.\n\nReturns an array of Markdown badges.\n\n\n\n"
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
    "category": "Function",
    "text": "gen_file(file_path::AbstractString, text::AbstractString) -> Int\n\nCreate a new file containing some given text. Always ends the file with a newline.\n\nArguments\n\nfile::AbstractString: Path to the file to be created.\ntext::AbstractString: Text to write to the file.\n\nReturns the number of bytes written to the file.\n\n\n\n"
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
    "category": "Function",
    "text": "substitute(template::AbstractString, view::Dict{String, Any}) -> String\n\nReplace placeholders in template with values in view via Mustache. template is not modified.\n\nFor information on how to structure template, see \"Defining Template Files\" section in Custom Plugins.\n\nNote: Conditionals in template without a corresponding key in view won't error, but will simply be evaluated as false.\n\n\n\nsubstitute(\n    template::AbstractString,\n    pkg_template::Template;\n    view::Dict{String, Any}=Dict{String, Any}(),\n) -> String\n\nReplace placeholders in template, using some default replacements based on the pkg_template and additional ones in view. template is not modified.\n\n\n\n"
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
    "category": "Type",
    "text": "Badge(hover::AbstractString, image::AbstractString, link::AbstractString) -> Badge\n\nA Badge contains the data necessary to generate a Markdown badge.\n\nArguments\n\nhover::AbstractString: Text to appear when the mouse is hovered over the badge.\nimage::AbstractString: URL to the image to display.\nlink::AbstractString: URL to go to upon clicking the badge.\n\n\n\n"
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
    "category": "Function",
    "text": "format(b::Badge)\n\nReturn badge's data formatted as a Markdown string.\n\n\n\n"
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
    "category": "Function",
    "text": "version_floor(v::VersionNumber=VERSION) -> String\n\nFormat the given Julia version.\n\nKeyword arguments\n\nv::VersionNumber=VERSION: Version to floor.\n\nReturns \"major.minor\" for the most recent release version relative to v. For prereleases with v.minor == v.patch == 0, returns \"major.minor-\".\n\n\n\n"
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
    "location": "pages/licenses.html#Licenses-1",
    "page": "Licenses",
    "title": "Licenses",
    "category": "section",
    "text": "Many open-source licenses are available for use with PkgTemplates, but if you see that one is missing, don't hesitate to open an issue or PR."
},

{
    "location": "pages/licenses.html#PkgTemplates.available_licenses",
    "page": "Licenses",
    "title": "PkgTemplates.available_licenses",
    "category": "Function",
    "text": "available_licenses([io::IO]) -> Void\n\nPrint the names of all available licenses.\n\n\n\n"
},

{
    "location": "pages/licenses.html#available_licenses-1",
    "page": "Licenses",
    "title": "available_licenses",
    "category": "section",
    "text": "available_licenses"
},

{
    "location": "pages/licenses.html#PkgTemplates.show_license",
    "page": "Licenses",
    "title": "PkgTemplates.show_license",
    "category": "Function",
    "text": "show_license([io::IO], license::AbstractString) -> Void\n\nPrint the text of license.\n\n\n\n"
},

{
    "location": "pages/licenses.html#show_license-1",
    "page": "Licenses",
    "title": "show_license",
    "category": "section",
    "text": "show_license"
},

{
    "location": "pages/licenses.html#Helper-Functions-1",
    "page": "Licenses",
    "title": "Helper Functions",
    "category": "section",
    "text": ""
},

{
    "location": "pages/licenses.html#PkgTemplates.read_license",
    "page": "Licenses",
    "title": "PkgTemplates.read_license",
    "category": "Function",
    "text": "read_license(license::AbstractString) -> String\n\nReturns the contents of license. Errors if it is not found. Use available_licenses to view available licenses.\n\n\n\n"
},

{
    "location": "pages/licenses.html#read_license-1",
    "page": "Licenses",
    "title": "read_license",
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
