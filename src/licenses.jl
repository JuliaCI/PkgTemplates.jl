const LICENSE_DIR = normpath(joinpath(@__DIR__, "..", "licenses"))
const LICENSES = Dict(
    "MIT" => "MIT \"Expat\" License",
    "BSD" => "Simplified \"2-clause\" BSD License",
    "ISC" => "Internet Systems Consortium License",
    "ASL" => "Apache License, Version 2.0",
    "MPL" => "Mozilla Public License, Version 2.0",
    "GPL-2.0+" => "GNU Public License, Version 2.0+",
    "GPL-3.0+" => "GNU Public License, Version 3.0+",
    "LGPL-2.1+" => "Lesser GNU Public License, Version 2.1+",
    "LGPL-3.0+" => "Lesser GNU Public License, Version 3.0+"
)

"""
    available_licenses([io::IO]) -> Nothing

Print the names of all available licenses.
"""
available_licenses(io::IO) = println(io, join(("$k: $v" for (k, v) in LICENSES), "\n"))
available_licenses() = available_licenses(STDOUT)

"""
    show_license([io::IO], license::AbstractString) -> Nothing

Print the text of `license`. Errors if the license is not found.
"""
show_license(io::IO, license::AbstractString) = println(io, read_license(license))
show_license(license::AbstractString) = show_license(STDOUT, license)

"""
    read_license(license::AbstractString) -> String

Returns the contents of `license`. Errors if the license is not found. Use
[`available_licenses`](@ref) to view available licenses.
"""
function read_license(license::AbstractString)
    path = joinpath(LICENSE_DIR, license)
    if isfile(path)
        return string(readchomp(path))
    else
        throw(ArgumentError("License '$license' is not available"))
    end
end
