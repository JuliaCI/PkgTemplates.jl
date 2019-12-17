def main(ctx):
  pipelines = []
  for arch in ["amd64"]:
    for julia in ["1.0", "1.3"]:
      pipelines.append(pipeline(arch, julia))
  return pipelines

def pipeline(arch, julia):
  return {
    "kind": "pipeline",
    "type": "docker",
    "name": "Julia %s - %s" % (julia, arch),
    "platform": {
      "os": "linux",
      "arch": arch,
    },
    "steps": [
      {
        "name": "test",
        "image": "julia:%s" % julia,
        "commands": [
          "julia -e 'using InteractiveUtils; versioninfo()'",
          "julia --project=@. -e 'using Pkg; Pkg.instantiate(); Pkg.build(); Pkg.test();'",
        ],
      },
    ],
  }
