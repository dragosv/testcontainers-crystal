# Testcontainers for Crystal

Testcontainers for Crystal provides lightweight, throwaway Docker containers for integration testing. Inspired by the [Testcontainers](https://testcontainers.org) ecosystem and ported from [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby), this library uses [docr](https://github.com/marghidanu/docr) to interact with the Docker Engine API.

## Features

- **Generic container support** — run any Docker image with a fluent configuration API
- **Wait strategies** — wait for logs, TCP ports, HTTP endpoints, or healthchecks
- **Pre-configured containers** — ready-to-use containers for popular services:
  - Redis
  - PostgreSQL
  - MySQL
  - MariaDB
  - MongoDB
  - Nginx
  - RabbitMQ
  - Elasticsearch
- **Network support** — create and manage Docker networks for multi-container scenarios
- **Block-based lifecycle** — automatically start and clean up containers

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  testcontainers:
    github: testcontainers/testcontainers-crystal
```

Then run:

```sh
shards install
```

## Requirements

- Crystal >= 1.10.0
- Docker daemon running and accessible via `/var/run/docker.sock`

## Quick Start

### Generic Container

```crystal
require "testcontainers"

# Create and start a Redis container
container = Testcontainers::DockerContainer.new("redis:7-alpine")
  .with_exposed_port(6379)
  .with_name("my-test-redis")

container.start

# Get connection details
host = container.host           # => "localhost"
port = container.mapped_port(6379) # => 32768 (random mapped port)

# Run your tests...
# ...

# Clean up
container.stop
container.remove
```

### Block-based Lifecycle

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("redis:7-alpine")
  .with_exposed_port(6379)

container.use do |c|
  host = c.host
  port = c.mapped_port(6379)
  # Container is running here...
end
# Container is automatically stopped and removed
```

### Redis Container

```crystal
require "testcontainers"

container = Testcontainers::RedisContainer.new
container.start

url = container.redis_url
# => "redis://localhost:32768/0"

container.stop
container.remove
```

### PostgreSQL Container

```crystal
require "testcontainers"

container = Testcontainers::PostgresContainer.new(
  username: "myuser",
  password: "mypass",
  database: "mydb"
)
container.start

url = container.database_url
# => "postgres://myuser:mypass@localhost:32768/mydb"

container.stop
container.remove
```

### MySQL Container

```crystal
require "testcontainers"

container = Testcontainers::MysqlContainer.new
container.start

url = container.database_url
# => "mysql://test:test@localhost:32768/test"

container.stop
container.remove
```

### MongoDB Container

```crystal
require "testcontainers"

container = Testcontainers::MongoContainer.new
  .with_username("admin")
  .with_password("secret")
container.start

url = container.connection_url
# => "mongodb://admin:secret@localhost:32768/test"

container.stop
container.remove
```

### Nginx Container

```crystal
require "testcontainers"

container = Testcontainers::NginxContainer.new
container.start

url = container.base_url
# => "http://localhost:32768"

container.stop
container.remove
```

### RabbitMQ Container

```crystal
require "testcontainers"

container = Testcontainers::RabbitmqContainer.new
container.start

amqp_url = container.connection_url
# => "amqp://guest:guest@localhost:32768"

mgmt_url = container.management_url
# => "http://localhost:32769"

container.stop
container.remove
```

## Configuration API

The `DockerContainer` class provides a fluent API for configuration:

```crystal
container = Testcontainers::DockerContainer.new("myimage:latest")
  .with_name("my-container")                      # Container name
  .with_exposed_port(8080)                         # Expose a port (random host mapping)
  .with_exposed_ports(8080, 8443)                  # Expose multiple ports
  .with_fixed_exposed_port(8080, 18080)            # Fixed port mapping
  .with_env("KEY", "VALUE")                        # Environment variable
  .with_env({"K1" => "V1", "K2" => "V2"})         # Multiple env vars from Hash
  .with_command("server", "--port", "8080")        # Container command
  .with_entrypoint("/bin/sh", "-c")                # Entrypoint
  .with_working_dir("/app")                        # Working directory
  .with_label("app", "test")                       # Label
  .with_labels({"env" => "ci"})                    # Multiple labels
  .with_volume("/data")                            # Volume
  .with_filesystem_bind("/host", "/container")     # Bind mount
  .with_healthcheck(                               # Healthcheck
    test: "curl -f http://localhost/",
    interval: 5.0,
    timeout: 3.0,
    retries: 3,
    shell: true
  )
```

## Wait Strategies

Wait strategies determine how to detect when a container is ready:

```crystal
# Wait for a log message (default for RedisContainer)
container.with_wait_for_logs(/Ready to accept connections/)

# Wait for a TCP port to be open (default when exposed_ports are set)
container.with_wait_for_tcp_port(8080)

# Wait for a healthcheck to pass (default for PostgresContainer)
container.with_wait_for_healthcheck

# Wait for an HTTP endpoint
container.with_wait_for_http(
  path: "/health",
  container_port: 8080,
  status: 200
)

# Custom wait strategy
container.with_wait_for do |c|
  # Custom logic using c.logs, c.exec, etc.
end
```

## Container Operations

```crystal
container.start       # Start the container
container.stop        # Stop gracefully
container.stop!       # Force stop (kill)
container.restart     # Restart
container.pause       # Pause
container.unpause     # Unpause
container.remove      # Remove/delete
container.kill        # Kill with signal

# Status checks
container.running?    # => true/false
container.exited?     # => true/false
container.paused?     # => true/false
container.healthy?    # => true/false
container.exists?     # => true/false
container.status      # => "running", "exited", etc.

# Information
container.host              # => "localhost"
container.mapped_port(8080) # => 32768
container.first_mapped_port # => 32768
container.logs              # => "container output..."
container.info              # => full inspect data
container.get_env("KEY")    # => "VALUE"

# Execute commands
output = container.exec(["echo", "hello"])
# => "hello\n"
```

## Docker Networks

```crystal
require "testcontainers"

# Create a network
network = Testcontainers::Network.new(name: "my-test-network")
network.create!

# Use with containers (via HostConfig NetworkMode)
# ...

# Clean up
network.remove

# Block-based lifecycle
Testcontainers::Network.create(name: "my-net") do |network|
  # Network is available here
end
# Network is automatically removed
```

## Running Tests

```sh
# Run unit tests
crystal spec

# Run integration tests (requires Docker)
crystal spec spec/integration_spec.cr -Dintegration
```

## Project Structure

```
testcontainers-crystal/
├── shard.yml
├── src/
│   └── testcontainers.cr                    # Main entry point
│   └── testcontainers/
│       ├── version.cr                       # Version constant
│       ├── errors.cr                        # Custom exceptions
│       ├── logger.cr                        # Logging setup
│       ├── patches.cr                       # Docr monkey-patches
│       ├── docker_client.cr                 # Docker API client wrapper
│       ├── docker_container.cr              # Core container class
│       ├── network.cr                       # Network management
│       └── containers/
│           ├── redis.cr                     # RedisContainer
│           ├── postgres.cr                  # PostgresContainer
│           ├── mysql.cr                     # MysqlContainer
│           ├── mariadb.cr                   # MariadbContainer
│           ├── mongo.cr                     # MongoContainer
│           ├── nginx.cr                     # NginxContainer
│           ├── rabbitmq.cr                  # RabbitmqContainer
│           └── elasticsearch.cr             # ElasticsearchContainer
└── spec/
    ├── spec_helper.cr
    ├── docker_container_spec.cr             # Unit tests for DockerContainer
    ├── containers_spec.cr                   # Unit tests for preset containers
    ├── network_spec.cr                      # Unit tests for Network
    └── integration_spec.cr                  # Integration tests (require Docker)
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Acknowledgements

- [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby) — the Ruby implementation this library is based on
- [docr](https://github.com/marghidanu/docr) — Crystal Docker Engine API client
- [Testcontainers](https://testcontainers.org) — the original Java project and ecosystem
