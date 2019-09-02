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
        @test sprint(show, Readme()) == rstrip(expected)
    end

    @testset "Template" begin
        expected = """
            Template:
              authors: ["$USER"]
              develop: true
              dir: "$(Pkg.devdir())"
              git: true
              host: "github.com"
              julia_version: v"1.0.0"
              manifest: false
              ssh: false
              user: "$USER"
              plugins:
                Readme:
                  file: "$DEFAULTS_DIR/README.md"
                  destination: "README.md"
                  inline_badges: false
                Tests:
                  file: "$DEFAULTS_DIR/runtests.jl"
                Gitignore:
                  ds_store: true
                  dev: true
                License:
                  path: "$LICENSE_DIR/MIT"
                  destination: "LICENSE"
            """
    end
end
