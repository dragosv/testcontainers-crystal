# Quickstart

Testcontainers for Crystal integrates with Crystal's built-in `spec` framework and the `crystal spec` command.

It is designed for integration and end-to-end tests, helping you spin up and manage the lifecycle of container-based dependencies via Docker.

## 1. System requirements

Please read the [System Requirements](../system_requirements/index.md) page before you start.

## 2. Install Testcontainers for Crystal

We use Shards for dependency management. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  testcontainers:
    github: testcontainers/testcontainers-crystal
    version: "~> 0.1.0"
```

Then run:

```bash
shards install
```

The shard provides the `Testcontainers` module:

| Module              | Description                                                                                |
|---------------------|--------------------------------------------------------------------------------------------|
| `Testcontainers`    | High-level API with container classes, wait strategies, pre-configured modules, networks.  |

The library uses [docr](https://github.com/marghidanu/docr) internally as the low-level Docker client.

## 3. Spin up Redis

```crystal
require "testcontainers"
require "spec"

describe "Quickstart" do
  it "works with Redis" do
    container = Testcontainers::DockerContainer.new("redis:7")
      .with_exposed_port(6379)
      .with_wait_for_logs(/Ready to accept connections/)

    begin
      container.start

      host = container.host
      port = container.mapped_port(6379)
      puts "Redis available at #{host}:#{port}"
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

`DockerContainer` receives the image name and is configured with a fluent API.

- `with_exposed_port(6379)` exposes port 6379 from the container and maps it to a random available host port — just like `docker run -p 6379`.
- `with_wait_for_logs(/.../)` validates when a container is ready to receive traffic. In this case, we check for the log message that Redis emits when ready.

When you use `with_exposed_port`, Docker maps the container port to a random available host port. This is crucial for parallelization — if you add multiple tests, each starts its own Redis container on a different random port.

`start` pulls the image (if needed), creates, starts the container, and executes the wait strategy.

All containers must be removed at some point, otherwise they will run until the host is overloaded. Using `begin/ensure` blocks ensures cleanup happens even if the test raises.

!!! tip

    Look at [Garbage Collector](../features/garbage_collector.md) to learn more about resource cleanup patterns.

## 4. Connect your code to the container

In a real project, you would pass this endpoint to your Redis client library. This snippet retrieves the endpoint from the container we just started:

```crystal
host = container.host
port = container.mapped_port(6379)

# Use host:port with your Redis client library
# For example: "redis://#{host}:#{port}"
```

We expose only one port, so the mapping is straightforward.

!!! tip

    If you expose more than one port, use `mapped_port` with the specific container port you need.

## 5. Run the test

Run the test via:

```bash
crystal spec
```

For integration tests that require Docker:

```bash
crystal spec -Dintegration
```

## 6. Want to go deeper with Redis?

You can find a more complete Redis example using the pre-configured module in our [Redis module](../modules/redis.md) documentation.

Or use any of the other pre-configured [modules](../modules/index.md):

- [PostgreSQL](../modules/postgres.md)
- [MySQL](../modules/mysql.md)
- [Redis](../modules/redis.md)
- [MongoDB](../modules/mongodb.md)
