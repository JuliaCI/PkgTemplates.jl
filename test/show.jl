const DEFAULTS_DIR = contractuser(PT.DEFAULTS_DIR)
const LICENSE_DIR = contractuser(PT.LICENSE_DIR)

@testset "Show methods" begin
    @testset "Plugins" begin
        expected = """
            Readme:
              file: "$DEFAULTS_DIR/README.md"
              destination: "README.md"
              inline_badges: false
            """
        @test sprint(show, MIME("text/plain"), Readme()) == rstrip(expected)
    end

    @testset "Template" begin
        expected = """
            Template:
              authors: ["$USER"]
              develop: true
              dir: "$(contractuser(Pkg.devdir()))"
              git: true
              host: "github.com"
              julia_version: v"1.0.0"
              manifest: false
              ssh: false
              user: "$USER"
              plugins:
                Gitignore:
                  ds_store: true
                  dev: true
                License:
                  path: "$LICENSE_DIR/MIT"
                  destination: "LICENSE"
                Readme:
                  file: "$DEFAULTS_DIR/README.md"
                  destination: "README.md"
                  inline_badges: false
                Tests:
                  file: "$DEFAULTS_DIR/runtests.jl"
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
