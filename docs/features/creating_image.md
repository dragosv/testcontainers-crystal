# Creating a Docker image

Testcontainers for Crystal pulls Docker images automatically when creating and starting containers. If the image is not available locally, it will be downloaded from the configured registry (Docker Hub by default).

## Automatic image pulling

When you start a `DockerContainer`, the image is pulled automatically:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "password")
  .start
```

If the image `postgres:16` is not present locally, Testcontainers will automatically pull it before creating the container.

## Using private registries

If your image is hosted in a private registry, ensure your Docker daemon is authenticated before running tests:

```bash
docker login my-registry.example.com
```

Testcontainers will use the credentials stored by Docker for image pulls.

## Low-level image management

For advanced use cases, you can manage images directly through the `docr` library:

```crystal
require "docr"

api = Docr::API.new(Docr::Client.new)

# Pull an image
api.images.create("alpine", tag: "latest")

# List images
images = api.images.list

# Inspect an image
api.images.inspect("alpine:latest")
```

!!! note

    For most testing scenarios, you do not need to manage images directly. `DockerContainer#start` handles image pulling transparently.
