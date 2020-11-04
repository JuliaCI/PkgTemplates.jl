@info "Running interactive tests"

using PkgTemplates: @with_kw_noshow

const CR = "\r"
const LF = "\n"
const UP = "\eOA"
const DOWN = "\eOB"
const ALL = "a"
const NONE = "n"
const DONE = "d"
const SIGINT = "\x03"

# Because the plugin selection dialog prints directly to stdin in the same way
# as we do here, and our input prints happen first, we're going to need to insert
# the plugin selection prints ourselves, and then "undo" the extra ones at the end
# by consuming whatever is left in stdin.
const NDEFAULTS = length(PT.default_plugins())
const SELECT_DEFAULTS = (CR * DOWN)^NDEFAULTS

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
        if VERSION < v"1.1"
            @test_broken generic(Union{String, Nothing}, "nothing") === nothing
        else
            @test generic(Union{String, Nothing}, "nothing") === nothing
        end

        @test_throws ArgumentError generic(Int, "hello")
        @test_throws ArgumentError generic(Float64, "hello")
        @test_throws ArgumentError generic(Bool, "hello")
    end

    @testset "input_tips" begin
        @test isempty(PT.input_tips(Int))
        @test PT.input_tips(Vector{String}) == ["comma-delimited"]
        @test PT.input_tips(Union{Vector{String}, Nothing}) ==
            ["'nothing' for nothing", "comma-delimited"]
        @test PT.input_tips(Union{String, Nothing}) == ["'nothing' for nothing"]
        @test PT.input_tips(Union{Vector{Secret}, Nothing}) ==
            ["'nothing' for nothing", "comma-delimited", "name only"]
    end

    @testset "Interactive name/type pair collection" begin
        name = gensym()
        @eval begin
            PT.@plugin struct $name <: PT.Plugin
                x::Int = 0
                y::String = ""
            end

            @test PT.interactive_pairs($name) == [:x => Int, :y => String]
            PT.customizable(::Type{$name}) = (:x => PT.NotCustomizable, :y => Float64, :z => Int)
            @test PT.interactive_pairs($name) == [:y => Float64, :z => Int]
        end
    end

    @testset "Simulated inputs" begin
        @testset "Default template" begin
            print(
                stdin.buffer,
                CR,        # Select user
                DONE,      # Finish menu
                USER, LF,  # Enter user
            )
            @test Template(; interactive=true) == Template(; user=USER)
        end

        @testset "Custom options, accept defaults" begin
            print(
                stdin.buffer,
                ALL, DONE,        # Customize all fields
                "user", LF,       # Enter user (don't assume we have default for this one).
                LF,               # Enter authors
                LF,               # Enter dir
                CR,               # Enter host
                CR,               # Enter julia
                SELECT_DEFAULTS,  # Pre-select default plugins
                DONE,             # Select no additional plugins
                DONE^NDEFAULTS,   # Don't customize plugins
            )
            @test Template(; interactive=true) == Template(; user="user")
            readavailable(stdin.buffer)
        end

        @testset "Custom options, custom values" begin
            nversions = VERSION.minor + 1
            print(
                stdin.buffer,
                ALL, DONE,           # Customize all fields
                "user", LF,          # Enter user
                "a, b", LF,          # Enter authors
                "~", LF,             # Enter dir
                DOWN^3, CR,          # Choose "Other" for host
                "x.com", LF,         # Enter host
                DOWN^nversions, CR,  # Choose "Other" for julia
                "0.7", LF,           # Enter Julia version
                SELECT_DEFAULTS,     # Pre-select default plugins
                DONE,                # Select no additional plugins
                DONE^NDEFAULTS,      # Don't customize plugins
            )
            @test Template(; interactive=true) == Template(;
                user="user",
                authors=["a", "b"],
                dir="~",
                host="x.com",
                julia=v"0.7",
            )
            readavailable(stdin.buffer)
        end

        @testset "Disabling default plugins" begin
            print(
                stdin.buffer,
                CR, DOWN^5, CR, DONE,    # Customize user and plugins
                USER, LF,                # Enter user
                SELECT_DEFAULTS,         # Pre-select default plugins
                UP, CR, UP^2, CR, DONE,  # Disable TagBot and Readme
                DONE^(NDEFAULTS - 2),    # Don't customize plugins
            )
            @test Template(; interactive=true) == Template(;
                user=USER,
                plugins=[!Readme, !TagBot],
            )
            readavailable(stdin.buffer)
        end

        @testset "Plugins" begin
            print(
                stdin.buffer,
                ALL, DONE,       # Customize all fields
                "true", LF,      # Enable ARM64
                "no", LF,        # Disable coverage
                "1.1,v1.2", LF,  # Enter extra versions
                "x.txt", LF,     # Enter file
                "Yes", LF,       # Enable Linux
                "false", LF,     # Disable OSX
                "TRUE", LF,      # Enable Windows
                "YES",  LF,      # Enable x64
                "NO", LF,        # Disable x86
            )
            @test PT.interactive(TravisCI) == TravisCI(;
                arm64=true,
                coverage=false,
                extra_versions=["1.1", "v1.2"],
                file="x.txt",
                linux=true,
                osx=false,
                windows=true,
                x64=true,
                x86=false,
            )

            print(
                stdin.buffer,
                DOWN^2, CR,        # Select GitLabCI
                DOWN^2, CR, DONE,  # Customize index_md
                "x.txt", LF,       # Enter index file
            )
            @test PT.interactive(Documenter) == Documenter{GitLabCI}(; index_md="x.txt")

            print(
                stdin.buffer,
                CR, DOWN, CR, DONE,  # Customize name and destination
                "COPYING", LF,       # Enter destination
                CR,                  # Choose MIT for name (it's at the top)
            )
            @test PT.interactive(License) == License(; destination="COPYING", name="MIT")
        end

        @testset "Quotes" begin
            print(
                stdin.buffer,
                CR, DOWN^2, CR, DONE,  # Customize user and dir
                "\"me\"", LF,          # Enter user with quotes
                "\"~\"", LF,           # Enter home dir with quotes
            )
            result = Template(; interactive=true) == Template(; user="me", dir="~")
            if get(ENV, "CI", "false") == "true"
                @test_broken result
            else
                @test result
            end

            print(
                stdin.buffer,
                DOWN^2, CR, DONE,                        # Customize extra_versions
                "\"1.1.1\", \"^1.5\", \"nightly\"", LF,  # Enter versions with quotes
            )
            @test PT.interactive(TravisCI) == TravisCI(;
                extra_versions=["1.1.1", "^1.5", "nightly"],
            )
        end

        @testset "Union{T, Nothing} weirdness" begin
            print(
                stdin.buffer,
                DOWN, CR, DONE,  # Customize changelog
                "hello", LF,     # Enter changelog
            )
            @test PT.interactive(TagBot) == TagBot(; changelog="hello")

            print(
                stdin.buffer,
                DOWN, CR, DONE,  # Customize changelog
                "nothing", LF,   # Set to null
            )
            @test PT.interactive(TagBot) == TagBot(; changelog=nothing)
        end

        @testset "Only one field" begin
            print(
                stdin.buffer,
                DOWN, CR, DONE,  # Select "None" option
            )
            @test PT.interactive(Codecov) == Codecov()
        end

        @testset "Missing user" begin
            print(
                stdin.buffer,
                DONE,            # Customize nothing
                "username", LF,  # Enter user after it's prompted
            )
            mock(PT.default_user => () -> "") do _du
                @test Template(; interactive=true) == Template(; user="username")
            end
        end

        @testset "Interrupts" begin
            print(
                stdin.buffer,
                SIGINT,  # Send keyboard interrupt
            )
            @test Template(; interactive=true) === nothing
        end

        println()
    end
end
