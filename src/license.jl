"""
    show_license([license::AbstractString]) -> Void

Show all available license names, or prints the text of `license`.
"""
show_license() = println(join(["$k: $v" for (k, v) in LICENSES], "\n"))
show_license(license::AbstractString) = println(read_license(license))

"""
    read_license(licence::AbstractString) -> String

Returns the contents of `license`. Errors if it is not found. Use [`show_license`](@ref) to
view available licenses.
"""
function read_license(license::AbstractString)
    path = joinpath(LICENSE_DIR, license)
    if isfile(path)
        return string(readchomp(path))
    else
        throw(ArgumentError("License '$license' is not available"))
    end
end
