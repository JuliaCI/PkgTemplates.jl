pass = success(`julia --project -e 'using Pkg; Pkg.test(coverage=true)'`)
version = ARGS[1]
if !pass
    if version == "nightly"
        println("::error ::Tests failed on nightly Julia")
    else
        exit(1)
    end
end
