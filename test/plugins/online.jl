@testset "Online" begin
    template = Template(PkgTemplates.read_settings(joinpath(@__DIR__, "test_settings.toml")))
    gen_plugin(Online(), template, "test")
    PkgTemplates.delete(template, "test.jl")
end
