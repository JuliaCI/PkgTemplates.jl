"""
    show_license() -> Void

Show all available license names.
"""
function show_license()
    for (k, v) in LICENSES
        println("$k: $v")
    end
end

"""
    show_license(license::AbstractString) -> Void

Shows the text of a given `license`.

# Arguments
* `license::AbstractString`: Name of the license to be shown.
  The list of available licenses can be shown with `show_license()`.
"""
function show_license(license::AbstractString)
    println(read_license(license))
end

"""
    read_license(licence::AbstractString) -> String

Read the contents of the named `license`. Errors if it is not found.

# Arguments
* `license::AbstractString`: Name of the license to read.

Returns the license text.
"""
function read_license(license::AbstractString)
    path = joinpath(LICENSE_DIR, license)
    if isfile(path)
        return string(readchomp(path))
    else
        throw(ArgumentError("License '$license' is not available"))
    end
end
