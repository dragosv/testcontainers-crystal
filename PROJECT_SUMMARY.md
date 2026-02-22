# Testcontainers for Crystal — Project Summary

## Overview

A Crystal library for managing throwaway Docker containers in integration tests, inspired by [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby). Built on top of the [docr](https://github.com/marghidanu/docr) Crystal shard for Docker Engine API communication.

## Core Features

### Container Lifecycle Management
- Create, start, stop, restart, pause, unpause, kill, and remove containers
- Automatic image pulling on first start
- Status inspection (`running?`, `exited?`, `healthy?`, `exists?`)
- Container logs retrieval
- Command execution inside running containers (`exec`)

### Fluent Builder API
Method chaining for natural container configuration:

```crystal
container = Testcontainers::DockerContainer.new("postgres:15")
  .with_name("test-pg")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "secret")
  .with_label("app", "test")
  .with_working_dir("/data")
  .with_cmd(["postgres", "-c", "log_statement=all"])
  .start
```

### Wait Strategies
Built-in readiness checks composable on any container:
- **Log matching** — `wait_for_logs(message: /regex/, timeout:, interval:)`
- **TCP port** — `wait_for_tcp_port(port:, timeout:, interval:)`
- **HTTP endpoint** — `wait_for_http(port:, path:, status_code:, timeout:, interval:)`
- **Docker healthcheck** — `wait_for_healthcheck(timeout:, interval:)`

### Networking
- Network creation and removal
- Block-based lifecycle (auto-cleanup)
- Container network aliases for DNS-based service discovery

### Pre-configured Modules (8)
| Module | Image | Default Port | Connection Helper |
|--------|-------|-------------|-------------------|
| `PostgresContainer` | `postgres:latest` | 5432 | `connection_url` |
| `MySQLContainer` | `mysql:latest` | 3306 | `connection_url` |
| `MariaDBContainer` | `mariadb:latest` | 3306 | `connection_url` |
| `RedisContainer` | `redis:latest` | 6379 | `connection_url` |
| `MongoContainer` | `mongo:latest` | 27017 | `connection_url` |
| `NginxContainer` | `nginx:latest` | 80 | `base_url` |
| `RabbitMQContainer` | `rabbitmq:management` | 5672/15672 | `connection_url`, `management_url` |
| `ElasticsearchContainer` | `elasticsearch:8.11.0` | 9200 | `connection_url` |

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Crystal >= 1.10.0 |
| Package manager | Shards |
| Docker client | [docr](https://github.com/marghidanu/docr) v0.1.4 |
| Test framework | Crystal spec (built-in) |
| Docker communication | Unix socket (`/var/run/docker.sock`) via docr |

## Usage Examples

### Basic Container

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("nginx:latest")
  .with_exposed_port(80)
  .with_wait_for(:http, port: 80)
  .start

port = container.mapped_port(80)
puts "Nginx available at http://localhost:#{port}"

container.stop
container.remove
```

### PostgreSQL with Spec

```crystal
require "spec"
require "testcontainers"

describe "Database tests" do
  it "connects to PostgreSQL" do
    pg = Testcontainers::PostgresContainer.new
      .with_database("testdb")
      .start

    url = pg.connection_url
    url.should contain("postgres://")

    pg.stop
    pg.remove
  end
end
```

### Network Communication

```crystal
Testcontainers::Network.create("app-net") do |network|
  db = Testcontainers::PostgresContainer.new
    .with_network(network)
    .with_network_alias("database")
    .start

  app = Testcontainers::DockerContainer.new("myapp:latest")
    .with_network(network)
    .with_env("DB_HOST", "database")
    .start

  # app can reach db at hostname "database"

  app.stop; app.remove
  db.stop; db.remove
end
```

## File Structure

```
testcontainers-crystal/
├── shard.yml                                # Shard manifest
├── shard.lock                               # Locked dependency versions
├── README.md                                # Feature overview and usage
├── QUICKSTART.md                            # Quick start guide
├── ARCHITECTURE.md                          # Design documentation
├── CONTRIBUTING.md                          # Contribution guidelines
├── IMPLEMENTATION_GUIDE.md                  # Implementation details
├── PROJECT_SUMMARY.md                       # This file
├── CODE_OF_CONDUCT.md                       # Code of conduct
├── AGENTS.md                                # AI agent guidelines
├── LICENSE                                  # MIT License
├── .gitignore                               # Git configuration
├── src/
│   ├── testcontainers.cr                    # Main entry point (requires all modules)
│   └── testcontainers/
│       ├── version.cr                       # VERSION constant
│       ├── errors.cr                        # Exception hierarchy
│       ├── logger.cr                        # Log configuration
│       ├── patches.cr                       # Docr monkey-patches
│       ├── docker_client.cr                 # Singleton Docker client wrapper
│       ├── docker_container.cr              # Core container class (776 LOC)
│       ├── network.cr                       # Network management
│       └── containers/                      # Pre-configured modules
│           ├── postgres.cr                  # PostgreSQL
│           ├── mysql.cr                     # MySQL
│           ├── mariadb.cr                   # MariaDB
│           ├── redis.cr                     # Redis
│           ├── mongo.cr                     # MongoDB
│           ├── nginx.cr                     # Nginx
│           ├── rabbitmq.cr                  # RabbitMQ
│           └── elasticsearch.cr             # Elasticsearch
├── spec/
│   ├── spec_helper.cr                       # Spec configuration
│   ├── docker_container_spec.cr             # Core container unit tests
│   ├── containers_spec.cr                   # Preset container unit tests
│   ├── network_spec.cr                      # Network unit tests
│   └── integration_spec.cr                  # Integration tests (Docker required)
└── lib/                                     # Installed dependencies (gitignored)
```

## Implementation Stats

| Metric | Value |
|--------|-------|
| Total Lines of Code | ~2,290 |
| Source files | 16 |
| Core classes | `DockerContainer`, `Network`, `DockerClient` |
| Pre-configured modules | 8 |
| Wait strategies | 4 built-in |
| Unit test examples | 66 passing |
| Spec files | 4 |
| Documentation files | 8 |

## Testing

- **Unit tests** (`crystal spec`): 66 tests, 0 failures — run without Docker
- **Integration tests** (`crystal spec -Dintegration`): require Docker running
- All preset containers have unit tests verifying default configuration
- `DockerContainer` has comprehensive tests for fluent API, port normalization, env vars, labels, healthcheck config, and error cases

## Comparison with testcontainers-ruby

| Feature | testcontainers-ruby | testcontainers-crystal |
|---------|-------------------|----------------------|
| Language | Ruby | Crystal |
| Docker client | docker-api gem | docr shard |
| API style | Fluent builder | Fluent builder (method chaining) |
| Wait strategies | Log, TCP, HTTP, Healthcheck, Exec | Log, TCP, HTTP, Healthcheck |
| Preset containers | 10+ | 8 |
| Test framework | RSpec | Crystal spec |
| Type safety | Dynamic | Static (compile-time) |
| Performance | Interpreted | Compiled (native) |

## Platform Support

- macOS (Apple Silicon and Intel)
- Linux (x86_64, aarch64)
- Requires Docker or Docker Desktop running

## Future Enhancement Opportunities

1. **Docker Compose Integration** — Multi-container orchestration via compose files
2. **Container Reuse** — Persist containers across test runs for speed
3. **Exec Wait Strategy** — Wait for command execution success
4. **Volume Management** — Data persistence and mounting helpers
5. **Resource Reaper** — Background cleanup service (Ryuk)
6. **Additional Modules** — Kafka, NATS, Minio, Cassandra, etc.
7. **CI/CD Detection** — Automatic Docker host detection in CI environments
8. **Testcontainers Cloud** — Remote container execution support
