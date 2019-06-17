struct Online <: CustomPlugin
    gitignore::Vector{AbstractString}
end
Online() = Online([])

badges(::Online, user::AbstractString, pkg_name::AbstractString) = []

struct Remote
    base_url::String
    token::String
end

function talk_to(request, remote::Remote, url, args...)
    body = json(Dict(args...))
    if body == "{}"
        body = ""
    end
    response = request(
        string(remote.base_url, url),
        headers = Dict(
            "Travis-API-Version" => "3",
            "Content-Type" => "application/json",
            "Authorization" => "token $(remote.token)",
            "User-Agent" => "OnlinePackage/0.0.1"
        ),
        body = body
    )
    if response.status >= 300
        error("$(response.status) $(response.statustext): $(String(response.body))")
    end
    response.body
end

json_string(something) = something |> String |> JSON.parse

check_name(repo, repo_name) = repo["name"] == repo_name

exists(github_remote, repo_name) = any(
    let repo_name = repo_name
        repo -> check_name(repo, repo_name)
    end,
    # TODO: handle more than 100 repos
    json_string(talk_to(HTTP.get, github_remote, "/user/repos?per_page=100"))
)

get_github_remote(template::Template) =
    Remote("https://api.github.com", template.github_token)

function make_key(ssh_keygen_file, key_name)
    run(`$ssh_keygen_file -f $key_name -N "" -q`)
    read(string(key_name, ".pub"), String),
        read(key_name, String) |> chomp |> base64encode
end
make_key_at(temp_file, ssh_keygen_file, key_name) = cd(
    let ssh_keygen_file = ssh_keygen_file, key_name = key_name
        () -> make_key(ssh_keygen_file, key_name)
    end,
    temp_file
)

function delete_github_key(github_remote, github_keys, key, key_name)
    if key["title"] == key_name
        talk_to(HTTP.delete, github_remote, "$github_keys/$(key["id"])")
    end
    nothing
end

function delete_travis_key(travis_remote, repo_code, key, key_name)
    if key["name"] == key_name
        talk_to(HTTP.delete, travis_remote, "/repo/$repo_code/env_var/$(key["id"])")
    end
    nothing
end

function delete(template::Template, repo_name)
    github_remote = get_github_remote(template)
    if exists(github_remote, repo_name)
        talk_to(HTTP.delete, get_github_remote(template), "/repos/$(template.user)/$repo_name")
    end
    nothing
end

function gen_plugin(::Online, template::Template, package_name::AbstractString)
    repo_name = package_name * ".jl"
    user = template.user
    github_remote = get_github_remote(template)
    travis_remote = Remote("https://api.travis-ci.com", template.travis_token)

    if !exists(github_remote, repo_name)
        talk_to(HTTP.post, github_remote, "/user/repos", "name" => repo_name)
        sleep(1)
    end

    repo_code = json_string(talk_to(HTTP.get, travis_remote, "/repo/$user%2F$repo_name"))["id"]

    ssh_keygen_file = template.ssh_keygen_file
    key_name = "DOCUMENTER_KEY"

    public_key, private_key = mktempdir(
        let ssh_keygen_file = ssh_keygen_file, key_name = key_name
            temp_file -> make_key_at(temp_file, ssh_keygen_file, key_name)
        end
    )

    github_keys = "/repos/$user/$repo_name/keys"
    foreach(
        let github_remote = github_remote, github_keys = github_keys, key_name = key_name
            key -> delete_github_key(github_remote, github_keys, key, key_name)
        end,
        json_string(talk_to(HTTP.get, github_remote, github_keys))
    )
    talk_to(HTTP.post, github_remote, github_keys,
        "title" => key_name,
        "key" => public_key,
        "read_only" => false
    )

    travis_keys = "/repo/$repo_code/env_vars"
    foreach(
        let travis_remote = travis_remote, key_name = key_name
            key -> delete_travis_key(travis_remote, repo_code, key, key_name)
        end,
        json_string(talk_to(HTTP.get, travis_remote, travis_keys))["env_vars"]
    )
    talk_to(HTTP.post, travis_remote, travis_keys,
        "env_var.name" => "DOCUMENTER_KEY",
        "env_var.value" => private_key,
        "env_var.public" => false
    )
    nothing
end

interactive(::Type{Online}) = Online()
