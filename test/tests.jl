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

    t = Template(remote_prefix="https://github.com/invenia"; path=joinpath("x", "y", "z"))
    @test t.path == joinpath("x", "y", "z")

    t = Template(remote_prefix="https://github.com/invenia"; julia_version=v"0.1.2")
    @test t.julia_version == v"0.1.2"

    t = Template(remote_prefix="https://github.com/invenia"; git_config=Dict("x" => "y"))
    @test t.git_config == Dict("x" => "y")

    t = Template(
        remote_prefix="https://github.com/invenia",
        plugins = [GitHubPages(), TravisCI(), AppVeyor(), CodeCov()],
    )
    @test Set(keys(t.plugins)) == Set([GitHubPages, TravisCI, AppVeyor, CodeCov])
    @test Set(values(t.plugins)) == Set([GitHubPages(), TravisCI(), AppVeyor(), CodeCov()])


end
