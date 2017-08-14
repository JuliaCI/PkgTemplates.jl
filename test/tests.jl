const git_config = Dict(
    "user.name" => "Tester McTestFace",
    "user.email" => "email@web.site",
)

const fake_path = joinpath("fake", "path")
const test_file = "test.file"
template_text = """
            Hello, world
            {{PKGNAME}}
            {{VERSION}}}
            {{#DOCUMENTER}}Documenter{{/DOCUMENTER}}
            {{#CODECOV}}CodeCov{{/CODECOV}}
            {{#AFTER}}After{{/AFTER}}
            {{#OTHER}}Other{{/OTHER}}
            """
write(test_file, template_text)

@testset "Template creation" begin
    t = Template(remote_prefix="https://github.com/invenia")
    @test t.remote_prefix == "https://github.com/invenia/"
    @test t.license == nothing
    @test t.years == string(Dates.year(Dates.today()))
    @test t.authors == LibGit2.getconfig("user.name", "")
    @test t.path == Pkg.dir()
    @test t.julia_version == VERSION
    @test isempty(t.git_config)
    @test isempty(t.plugins)

    t = Template(remote_prefix="https://github.com/invenia"; license="MIT")
    @test t.license == "MIT"

    t = Template(remote_prefix="https://github.com/invenia"; years=2014)
    @test t.years == "2014"
    t = Template(remote_prefix="https://github.com/invenia"; years="2014-2015")
    @test t.years == "2014-2015"

    t = Template(remote_prefix="https://github.com/invenia"; authors="Some Guy")
    @test t.authors == "Some Guy"
    t = Template(remote_prefix="https://github.com/invenia"; authors=["Guy", "Gal"])
    @test t.authors == "Guy, Gal"

    t = Template(remote_prefix="https://github.com/invenia"; path=test_file)
    @test t.path == test_file

    t = Template(remote_prefix="https://github.com/invenia"; julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(remote_prefix="https://github.com/invenia"; git_config=git_config)
    @test t.git_config == git_config

    t = Template(
        remote_prefix="https://github.com/invenia",
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov()],
    )
    @test Set(keys(t.plugins)) == Set([GitHubPages, TravisCI, AppVeyor, CodeCov])
    @test Set(values(t.plugins)) == Set([GitHubPages(), TravisCI(), AppVeyor(), CodeCov()])

    @test_warn r".*" Template(;
        remote_prefix="https://github.com/invenia",
        plugins=[TravisCI(), TravisCI()],
    )

end

@testset "Plugin creation" begin
    p = AppVeyor()
    @test isempty(p.gitignore_files)
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "appveyor.yml")
    p = AppVeyor(; config_file=nothing)
    @test p.config_file == nothing
    p = AppVeyor(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError AppVeyor(; config_file=fake_path)

    p = TravisCI()
    @test isempty(p.gitignore_files)
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
    p = TravisCI(; config_file=nothing)
    @test p.config_file == nothing
    p = TravisCI(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError TravisCI(; config_file=fake_path)

    p = CodeCov()
    @test p.gitignore_files == ["*.jl.cov", "*.jl.*.cov", "*.jl.mem"]
    @test p.config_file == joinpath(PkgTemplates.DEFAULTS_DIR, "codecov.yml")
    p = CodeCov(; config_file=nothing)
    @test p.config_file == nothing
    p = CodeCov(; config_file=test_file)
    @test p.config_file == test_file
    @test_throws ArgumentError CodeCov(; config_file=fake_path)
end
