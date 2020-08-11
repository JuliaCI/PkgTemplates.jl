cmd = Cmd(`julia --project -e 'using Pkg; Pkg.test(coverage=true)'`; ignorestatus=true)
version = ARGS[1]
proc = run(cmd)
if proc.exitcode != 0
    if version == "nightly"
        println("::error ::Tests failed on nightly Julia")
    else
        exit(1)
    end
end
