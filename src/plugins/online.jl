"""
    struct Online <: Plugin

Put your package on github and travis, and connect the two with a ssh-key.
"""
struct Online <: Plugin
end

gitignore(::Online) = String[]
badges(::Online) = Badge[]
needs_username(::Online) = true

struct Remote
    base_url::String
    token::String
end

function talk_to(request, remote::Remote, url, arguments...)
    body = json(Dict(arguments...))
    if body == "{}"
        body = ""
    end
    response = request(
        string(remote.base_url, url),
        headers = Dict(
            "Travis-API-Version" => "3",
            "Content-Type" => "application/json",
            "Authorization" => "token $(remote.token)",
            "User-Agent" => "PkgTemplates"
        ),
        body = body
    )
    if response.status >= 300
        error("$(response.status) $(response.statustext): $(String(response.body))")
    end
    response.body
end

json_string(something) = JSON.parse(String(something))

exists(github_remote, repo_name) = any(
    repo["name"] == repo_name for repo in
        json_string(talk_to(HTTP.get, github_remote,
            "/user/repos?per_page=100"
        ))
)

get_github_remote(template::Template) =
    Remote("https://api.github.com", template.github_token)

function delete(template::Template, repo_name)
    github_remote = get_github_remote(template)
    if exists(github_remote, repo_name)
        talk_to(HTTP.delete, github_remote, "/repos/$(template.user)/$repo_name")
    end
    nothing
end

function validate(::Online, template::Template)
    if template.github_token == ""
        error("The online plugin requires a github token")
    elseif template.travis_token == ""
        error("The online plugin requires a travis token")
    end
end

function hook(::Online, template::Template, package_file::AbstractString)
    repo_name = basename(package_file)
    user = template.user
    github_remote = get_github_remote(template)
    travis_remote = Remote("https://api.travis-ci.com", template.travis_token)

    if !exists(github_remote, repo_name)
        talk_to(HTTP.post, github_remote, "/user/repos", "name" => repo_name)
        sleep(1)
    end

    repo_code = json_string(talk_to(HTTP.get, travis_remote,
        "/repo/$user%2F$repo_name"
    ))["id"]

    key_name = "DOCUMENTER_KEY"

    public_key, private_key = mktempdir() do temp
        cd(temp) do
            run(`$(template.ssh_keygen_file) -f $key_name -N "" -q`)
            (
                read("$key_name.pub", String),
                base64encode(chomp(read(key_name, String)))
            )
        end
    end

    github_keys = "/repos/$user/$repo_name/keys"
    for key in json_string(talk_to(HTTP.get, github_remote, github_keys))
        if key["title"] == key_name
            talk_to(HTTP.delete, github_remote, "$github_keys/$(key["id"])")
        end
    end
    talk_to(HTTP.post, github_remote, github_keys,
        "title" => key_name,
        "key" => public_key,
        "read_only" => false
    )

    travis_keys = "/repo/$repo_code/env_vars"
    for key in json_string(
        talk_to(HTTP.get, travis_remote, travis_keys)
    )["env_vars"]
        if key["name"] == key_name
            talk_to(HTTP.delete, travis_remote,
                "/repo/$repo_code/env_var/$(key["id"])"
            )
        end
    end
    talk_to(HTTP.post, travis_remote, travis_keys,
        "env_var.name" => key_name,
        "env_var.value" => private_key,
        "env_var.public" => false
    )
    nothing
end
