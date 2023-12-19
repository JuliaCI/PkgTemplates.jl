"""
A [`Plugin`](@ref) that only adds a [`Badge`](@ref) to the [`Readme`](@ref) file.

Concrete subtypes only need to implement a [`badges`](@ref) method.
"""
abstract type BadgePlugin <: Plugin end

"""
    BlueStyleBadge()

Adds a [`BlueStyle`](https://github.com/invenia/BlueStyle) badge to the [`Readme`](@ref) file.
"""
struct BlueStyleBadge <: BadgePlugin end

function badges(::BlueStyleBadge)
    return Badge(
        "Code Style: Blue",
        "https://img.shields.io/badge/code%20style-blue-4495d1.svg",
        "https://github.com/invenia/BlueStyle",
    )
end

"""
    ColPracBadge()

Adds a [`ColPrac`](https://github.com/SciML/ColPrac) badge to the [`Readme`](@ref) file.
"""
struct ColPracBadge <: BadgePlugin end

function badges(::ColPracBadge)
    return Badge(
        "ColPrac: Contributor's Guide on Collaborative Practices for Community Packages",
        "https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet",
        "https://github.com/SciML/ColPrac",
    )
end

"""
    PkgEvalBadge()

Adds a [`PkgEval` badge](https://github.com/JuliaCI/NanosoldierReports#pkgeval-reports) to the [`Readme`](@ref) file.
"""
struct PkgEvalBadge <: BadgePlugin end

function badges(::PkgEvalBadge)
    return Badge(
        "PkgEval",
        "https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/{{{PKG1}}}/{{{PKG}}}.svg",
        "https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/{{{PKG1}}}/{{{PKG}}}.html"
    )
end

function view(::PkgEvalBadge, t::Template, pkg::AbstractString)
    return Dict("PKG1" => first(pkg), "PKG" => pkg)
end
