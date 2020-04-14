notnothingtype(::Type{T}) where T = T
notnothingtype(::Type{Union{T, Nothing}}) where T = T

@testset "Interactive mode" begin
    @testset "convert_input has all required methods" begin
        Fs = mapreduce(union!, PT.concretes(PT.Plugin); init=Set()) do T
            map(notnothingtype, map(n -> fieldtype(T, n), fieldnames(T)))
        end
        foreach(Fs) do F
            @test hasmethod(PT.convert_input, Tuple{Type{Template}, Type{F}, AbstractString})
        end
    end

    @testset "input_tips" begin
        @test isempty(PT.input_tips(Int))
        @test PT.input_tips(Vector{String}) == ["comma-delimited"]
        @test PT.input_tips(Union{Vector{String}, Nothing}) ==
            ["empty for nothing", "comma-delimited"]
        @test PT.input_tips(Union{String, Nothing}) == ["empty for nothing"]
        @test PT.input_tips(Union{Vector{Secret}, Nothing}) ==
            ["empty for nothing", "comma-delimited", "name only"]
    end

    @testset "Interactive name/type pair collection" begin
        name = gensym()
        @eval begin
            struct $name <: PT.Plugin
                x::Int
                y::String
            end

            @test PT.interactive_pairs($name) == [:x => Int, :y => String]

            PT.not_customizable(::Type{$name}) = (:x,)
            @test PT.interactive_pairs($name) == [:y => String]

            PT.extra_customizable(::Type{$name}) = (:y => Float64, :z => Int)
            @test PT.interactive_pairs($name) == [:y => Float64, :z => Int]
        end
    end
end
