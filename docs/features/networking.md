# Networking and communicating with containers

There are two common cases for setting up communication with containers.

## Exposing ports to the host

The simplest case does not require additional network configuration. The host running the test connects directly to the container through a mapped port.

### Exposing container ports

Use `with_exposed_port` to expose a container port to a random host port:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)

container.start
```

When you use `with_exposed_port`, you should think of it as `docker run -p <port>`. Docker maps the container port to a random available port on your host.

This is important for parallelization: if you run multiple tests in parallel, each can start its own container — and each will be exposed on a different random port, avoiding conflicts.

### Getting the container host

Resolve the container address from the running container:

```crystal
host = container.host
```

!!! warning

    Do not hardcode `localhost`, `127.0.0.1`, or any other fixed address to access the container. The address may vary depending on the Docker environment (e.g., Docker Desktop, remote Docker host, CI environments).

### Getting the mapped port

Retrieve the random host port assigned by Docker:

```crystal
port = container.mapped_port(5432)
```

### Complete example

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)

begin
  container.start

  host = container.host
  port = container.mapped_port(5432)
  # Connect to postgres at host:port
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

## Creating networks

For container-to-container communication, create a custom Docker network. Containers on the same network can communicate using container names without exposing ports through the host.

### Creating a network

Use `Testcontainers::Network` to create a Docker network:

```crystal
network = Testcontainers::Network.new(name: "my-network", driver: "bridge")
network.create!
```

#### Network options

| Constructor parameter | Description                                                         |
|-----------------------|---------------------------------------------------------------------|
| `name`                | The network name (auto-generated if not provided).                  |
| `driver`              | Sets the network driver (default: `"bridge"`).                      |

### Network methods

| Method      | Description                                      |
|-------------|--------------------------------------------------|
| `create!`   | Creates the network in Docker (idempotent).      |
| `remove`    | Removes the network.                             |
| `info`      | Returns the network inspect data.                |
| `created?`  | Whether the network has been created.            |

### Complete example

```crystal
network = Testcontainers::Network.new(name: "app-network")

begin
  network.create!

  container = Testcontainers::DockerContainer.new("postgres:16")
    .with_env("POSTGRES_PASSWORD", "password")
    .with_exposed_port(5432)
    .with_wait_for_tcp_port(5432)

  container.start

  host = container.host
  port = container.mapped_port(5432)
  # Connect to postgres at host:port
ensure
  container.stop rescue nil
  container.remove rescue nil
  network.remove rescue nil
end
```

!!! tip

    When containers are on the same Docker network, they can communicate using container names directly — no port mapping to the host is needed. Use the container port (for example, `5432`), not the mapped host port.
