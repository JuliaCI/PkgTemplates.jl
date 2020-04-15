@info "Running interactive tests"

const CRLF = "\r\n"
const UP = "\eOA"
const DOWN = "\eOB"
const ALL = "a"
const NONE = "n"
const DONE = "d"

notnothingtype(::Type{T}) where T = T
notnothingtype(::Type{Union{T, Nothing}}) where T = T

struct FromString
    s::String
end

@testset "Interactive mode" begin
    @testset "Input conversion" begin
        generic(T, x) = PT.convert_input(PT.Plugin, T, x)
        @test generic(String, "foo") == "foo"
        @test generic(Float64, "1.23") == 1.23
        @test generic(Int, "01") == 1
        @test generic(Bool, "yes") === true
        @test generic(Bool, "True") === true
        @test generic(Bool, "No") === false
        @test generic(Bool, "false") === false
        @test generic(Vector{Int}, "1, 2, 3") == [1, 2, 3]
        @test generic(Vector{String}, "a, b,c") == ["a", "b", "c"]
        @test generic(FromString, "hello") == FromString("hello")
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
            PT.customizable(::Type{$name}) = (:x => PT.NotCustomizable, :y => Float64, :z => Int)
            @test PT.interactive_pairs($name) == [:y => Float64, :z => Int]
        end
    end

    @testset "Simulated inputs" begin
        # Default template (with required user input)
        print(
            stdin.buffer,
            DOWN^6, CRLF,  # Select user
            DONE,          # Finish menu
            USER, CRLF,    # Enter user
        )
        @test Template(; interactive=true) == Template(; user=USER)

        print(
            stdin.buffer,
            ALL, DONE,           # Customize all fields
            "a, b", CRLF,        # Enter authors
            "~", CRLF,           # Enter dir
            DOWN^4, CRLF, DONE,  # Disable License plugin
            DOWN^3, CRLF,        # Choose "Other" for host
            "x.com", CRLF,       # Enter host
            DOWN^6, CRLF,        # Choose "Other" for julia
            "0.7", CRLF,         # Enter Julia version
            DONE,                # Select no plugins
            "user", CRLF,        # Enter user
        )
        @test Template(; interactive=true) == Template(;
            authors=["a", "b"],
            dir="~",
            disable_defaults=[License],
            host="x.com",
            julia=v"0.7",
            user="user",
        )

        println()
    end
end
