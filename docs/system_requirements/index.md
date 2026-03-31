# System Requirements

This page describes the prerequisites for using Testcontainers for Crystal.

## Crystal

| Requirement | Minimum Version |
|-------------|:---------------:|
| Crystal     | 1.10.0          |
| macOS       | Supported       |
| Linux       | Supported       |

Testcontainers for Crystal is distributed as a Shard. Add it to your `shard.yml` and run `shards install`.

## Docker

A Docker-compatible container runtime must be installed and running. Testcontainers for Crystal communicates with the Docker Engine API over a Unix socket via the [docr](https://github.com/marghidanu/docr) library.

### Supported runtimes

| Runtime         | Supported | Notes                              |
|-----------------|:---------:|------------------------------------|
| Docker Desktop  | Yes       | macOS and Linux                    |
| Docker Engine   | Yes       | Linux                              |
| Colima          | Yes       | macOS, set `DOCKER_HOST` manually  |
| Podman          | Untested  | May work with Docker-compatible socket |
| Rancher Desktop | Untested  | May work with Docker-compatible socket |

### Docker socket detection

Testcontainers for Crystal looks for the Docker socket in this order:

1. `DOCKER_HOST` environment variable
2. `/var/run/docker.sock`
3. `~/.docker/run/docker.sock`

If your Docker runtime uses a non-standard socket path, set `DOCKER_HOST`:

```bash
export DOCKER_HOST=unix:///Users/$USER/.colima/default/docker.sock
```

## Network access

Container images are pulled from Docker Hub by default. Your environment must have network access to the registries hosting your desired images, or you must pre-pull images before running tests.

## CI Environments

Testcontainers for Crystal works in any CI environment that provides Docker access. See the following guides:

- [GitHub Actions](ci/github_actions.md)
- [GitLab CI/CD](ci/gitlab_ci.md)
- [Docker-in-Docker Patterns](ci/dind_patterns.md)
