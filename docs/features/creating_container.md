# How to create a container

Testcontainers' generic container support offers the greatest flexibility and makes it easy to use virtually any container image in the context of a temporary test environment. To interact or exchange data with a container, Testcontainers provides `DockerContainer` to configure and create the resource.

## DockerContainer

The `DockerContainer` is the primary class for creating containers. It receives the Docker image name and provides a fluent API for configuration:

```crystal
container = Testcontainers::DockerContainer.new("redis:7")
  .with_exposed_port(6379)
  .with_wait_for_logs(/Ready to accept connections/)

container.start

host = container.host
port = container.mapped_port(6379)

# ... use container ...

container.stop
container.remove
```

The `start` method pulls the image (if needed), creates the container, starts it, and executes the configured wait strategy to verify readiness.

## Container options

When creating a container, you can use fluent `with_*` methods on `DockerContainer` to configure it. The options are organized into functional categories.

### Basic options

#### with_exposed_port

Exposes a container port to the host. Docker assigns a random available host port — this is the recommended approach to avoid port conflicts.

```crystal
# Random host port (recommended)
container.with_exposed_port(8080)

# Specific host port
container.with_fixed_exposed_port(80, 8080)
```

After starting the container, retrieve the mapped port:

```crystal
mapped_port = container.mapped_port(8080)
```

#### with_env

Sets environment variables for the container.

```crystal
# Single variable
container.with_env("POSTGRES_PASSWORD", "secret")

# Multiple variables from a Hash
container.with_env({"POSTGRES_DB" => "mydb", "POSTGRES_USER" => "admin"})
```

#### Wait strategies

Sets the wait strategy to determine when the container is ready for use.

```crystal
container.with_wait_for_http(path: "/health", container_port: 8080)
container.with_wait_for_tcp_port(5432)
container.with_wait_for_logs(/Ready/)
container.with_wait_for_healthcheck
```

#### with_entrypoint

Specifies or overrides the container's `ENTRYPOINT`:

```crystal
container.with_entrypoint("/bin/sh", "-c")
```

#### with_command

Specifies or overrides the container's `CMD`:

```crystal
container.with_command("--config", "/etc/app.conf")
```

#### with_label

Applies Docker labels to the container:

```crystal
# Single label
container.with_label("team", "backend")

# Multiple labels from a Hash
container.with_labels({"app" => "myservice", "env" => "test"})
```

### Volume options

#### with_filesystem_bind

Mounts a host directory into the container:

```crystal
container.with_filesystem_bind("/host/path", "/container/path", "rw")
```

#### with_volume

Adds a named volume:

```crystal
container.with_volume("/data")
```

### Container name

#### with_name

Sets the container name:

```crystal
container.with_name("my-postgres")
```

## Container methods

After starting a container, `DockerContainer` exposes several useful methods.

### Getting the mapped port

```crystal
port = container.mapped_port(5432)
```

### Getting the host

```crystal
host = container.host
```

### Executing commands

Execute a command inside the running container and get the output:

```crystal
output = container.exec(["echo", "Hello from container"])
puts output # "Hello from container"
```

### Getting logs

Retrieve the container's stdout/stderr logs:

```crystal
logs = container.logs
puts logs
```

### Getting container status

```crystal
container.running?    # => true/false
container.exited?     # => true/false
container.paused?     # => true/false
container.healthy?    # => true/false
```

### Stopping and removing

```crystal
# Stop the container
container.stop

# Force-stop the container
container.stop!

# Remove the container
container.remove

# Force-remove
container.remove(force: true)
```

## Lifecycle

A typical container lifecycle in a test looks like this:

```
DockerContainer.new("image:tag")  →  configure  →  .start  →  test logic  →  .stop  →  .remove
```

The recommended cleanup pattern uses `begin/ensure`:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)

begin
  container.start

  # Test logic using the container...
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

Or use the `use` block for automatic cleanup:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)

container.use do |c|
  # Test logic using c...
end
# Container is automatically stopped and removed
```

## Examples

### NGINX container

```swift
let container = try await ContainerBuilder("nginx:1.26.3-alpine3.20")
    .withName("my-nginx")
    .withPortBinding(80, assignRandomHostPort: true)
    .withWaitStrategy(Wait.http(port: 80))
    .buildAsync()

try await container.start()
defer { Task { try? await container.stop(timeout: 10) } }

let port = try container.getMappedPort(80)
let host = container.host ?? "localhost"

let url = URL(string: "http://\(host):\(port)")!
let (_, response) = try await URLSession.shared.data(from: url)
let httpResponse = response as! HTTPURLResponse
assert(httpResponse.statusCode == 200)
```

### Container with command output

```swift
let container = try await ContainerBuilder("alpine:latest")
    .withCmd(["sh", "-c", "echo 'Hello from container' && sleep 10"])
    .buildAsync()

try await container.start()
defer { Task { try? await container.stop(timeout: 10) } }

try await Task.sleep(nanoseconds: 2_000_000_000)
let logs = try await container.getLogs()
print(logs) // "Hello from container\n"
```

## Supported commands

| Builder method                             | Description                                                                   |
|--------------------------------------------|-------------------------------------------------------------------------------|
| `withName(_:)`                             | Sets the container name.                                                      |
| `withEnvironment(_:_:)`                    | Sets a single environment variable.                                           |
| `withEnvironment(_:)` (dictionary)         | Sets multiple environment variables from a dictionary.                        |
| `withLabel(_:_:)`                          | Applies a single label to the container.                                      |
| `withLabel(_:)` (dictionary)               | Applies multiple labels from a dictionary.                                    |
| `withPortBinding(_:assignRandomHostPort:)` | Publishes a container port, optionally to a random host port.                 |
| `withPortBinding(hostPort:containerPort:)` | Publishes a container port to a specific host port.                           |
| `withEntrypoint(_:)`                       | Specifies or overrides the `ENTRYPOINT`.                                      |
| `withCmd(_:)`                              | Specifies or overrides the `CMD`.                                             |
| `withWaitStrategy(_:)`                     | Sets the wait strategy to indicate when the container is ready.               |
| `withNetwork(_:)`                          | Assigns a Docker network to the container.                                    |
| `withNetworkAliases(_:)`                   | Assigns network-scoped aliases to the container.                              |
| `build()`                                  | Builds a container instance (local only, does not create in Docker).          |
| `buildAsync()`                             | Builds and creates the container in Docker (pulls image, creates container).  |

!!! tip

    Testcontainers for Swift detects your Docker host configuration automatically. You do **not** need to set the Docker daemon socket manually.
