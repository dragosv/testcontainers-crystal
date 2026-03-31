# Low-level API access

Testcontainers for Crystal is built on top of [docr](https://github.com/marghidanu/docr), a low-level Docker HTTP client that communicates with the Docker Engine API over a Unix socket. While the high-level `Testcontainers` module is recommended for test scenarios, you can access the Docker client directly for advanced use cases.

## Accessing the Docker client

The `Testcontainers::DockerClient` provides access to the underlying `Docr::API`:

```crystal
require "testcontainers"

api = Testcontainers::DockerClient.api
```

## Container operations

```crystal
# Start, stop, and remove containers
api.containers.start(container_id)
api.containers.stop(container_id)
api.containers.delete(container_id, force: true)

# Inspect a container
inspect = api.containers.inspect(container_id)

# Get logs
io = api.containers.logs(container_id, stdout: true, stderr: true)
logs = io.gets_to_end
```

## Image operations

```crystal
# Pull an image
api.images.create("alpine", tag: "latest")

# Inspect an image
api.images.inspect("alpine:latest")
```

## Network operations

```crystal
# Create a network
config = Docr::Types::NetworkConfig.new(name: "my-network", driver: "bridge")
api.networks.create(config)

# Remove a network
api.networks.delete(network_id)
```

## Using docr directly

For even lower-level access, import `docr` directly:

```crystal
require "docr"

api = Docr::API.new(Docr::Client.new)

# List containers
containers = api.containers.list

# List images
images = api.images.list
```

!!! warning

    The low-level API is not covered by the same stability guarantees as the high-level `Testcontainers` module. Method signatures may change between minor versions.

## Docker socket detection

The `Testcontainers::DockerClient` automatically detects the Docker socket in this order:

1. `DOCKER_HOST` environment variable
2. `/var/run/docker.sock`
3. `~/.docker/run/docker.sock` (Docker Desktop on macOS)

See [Custom Configuration](configuration.md) for more details on Docker host detection.
