const TEMPLATES_DIR = contractuser(PT.TEMPLATES_DIR)
const LICENSES_DIR = joinpath(TEMPLATES_DIR, "licenses")

@testset "Show methods" begin
    @testset "Plugins" begin
        expected = """
            Readme:
              file: "$(joinpath(TEMPLATES_DIR, "README.md"))"
              destination: "README.md"
              inline_badges: false
            """
        @test sprint(show, MIME("text/plain"), Readme()) == rstrip(expected)
    end

    @testset "Template" begin
        expected = """
            Template:
              authors: ["Chris de Graaf <chrisadegraaf@gmail.com>"]
              dir: "~/.local/share/julia/dev"
              host: "github.com"
              julia: v"1.0.0"
              user: "$USER"
              plugins:
        """
        expected = """
            Template:
              authors: ["$USER"]
              dir: "$(contractuser(Pkg.devdir()))"
              host: "github.com"
              julia: v"1.0.0"
              user: "$USER"
              plugins:
                Git:
                  ignore: String[]
                  ssh: false
                  manifest: false
                  gpgsign: false
                License:
                  path: "$(joinpath(LICENSES_DIR, "MIT"))"
                  destination: "LICENSE"
                ProjectFile:
                  version: v"0.1.0"
                Readme:
                  file: "$(joinpath(TEMPLATES_DIR, "README.md"))"
                  destination: "README.md"
                  inline_badges: false
                SrcDir:
                  file: "$(joinpath(TEMPLATES_DIR, "src", "module.jl"))"
                Tests:
                  file: "$(joinpath(TEMPLATES_DIR, "test", "runtests.jl"))"
                  project: false
            """
        @test sprint(show, MIME("text/plain"), tpl(; authors=USER)) == rstrip(expected)
    end

    @testset "show as serialization" begin
        # Equality is not implemented for Template, so check the string form.
        t1 = tpl()
        t2 = eval(Meta.parse(sprint(show, t1)))
        @test sprint(show, t1) == sprint(show, t2)
    end
end
