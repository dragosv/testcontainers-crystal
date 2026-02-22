# Implementation Guide — Testcontainers Crystal

## Overview

This is a complete Crystal implementation of Testcontainers, providing Docker container management for testing. Built on top of the [docr](https://github.com/marghidanu/docr) shard, following patterns from the [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby) implementation.

## What You Have

A fully functional Crystal library with:

### Core Components (~1,640 lines of source code)

1. **DockerContainer** — Full container lifecycle with fluent builder API (776 LOC)
2. **DockerClient** — Singleton wrapper around docr's API (52 LOC)
3. **Network** — Bridge network creation and block-based lifecycle (100 LOC)
4. **Errors** — Typed exception hierarchy (46 LOC)
5. **Patches** — Minimal docr compatibility fixes (9 LOC)
6. **8 Preset Containers** — PostgreSQL, MySQL, MariaDB, Redis, MongoDB, Nginx, RabbitMQ, Elasticsearch (~647 LOC)

### Test Suite (~632 lines)

- **docker_container_spec.cr** — 295 LOC, comprehensive unit tests for fluent API
- **containers_spec.cr** — 185 LOC, unit tests for all 8 preset containers
- **network_spec.cr** — 35 LOC, network management tests
- **integration_spec.cr** — 115 LOC, Docker integration tests (gated behind `-Dintegration`)
- **66 unit tests passing**, 0 failures

### Documentation

- **README.md** — Features, installation, usage guide
- **QUICKSTART.md** — 5-minute getting started
- **ARCHITECTURE.md** — System design and patterns
- **CONTRIBUTING.md** — How to contribute
- **PROJECT_SUMMARY.md** — Implementation overview
- **IMPLEMENTATION_GUIDE.md** — This detailed guide

## Directory Structure

```
testcontainers-crystal/
├── shard.yml                                # Shard manifest (docr dependency)
├── shard.lock                               # Locked versions
├── src/
│   ├── testcontainers.cr                    # Entry point — requires all modules
│   └── testcontainers/
│       ├── version.cr                       # VERSION = "0.1.0"
│       ├── errors.cr                        # Exception hierarchy (46 LOC)
│       ├── logger.cr                        # Log configuration (5 LOC)
│       ├── patches.cr                       # Docr ExecConfig fix (9 LOC)
│       ├── docker_client.cr                 # Singleton Docker client (52 LOC)
│       ├── docker_container.cr              # Core container class (776 LOC)
│       ├── network.cr                       # Network management (100 LOC)
│       └── containers/
│           ├── postgres.cr                  # PostgreSQL preset (96 LOC)
│           ├── mysql.cr                     # MySQL preset (104 LOC)
│           ├── mariadb.cr                   # MariaDB preset (97 LOC)
│           ├── redis.cr                     # Redis preset (66 LOC)
│           ├── mongo.cr                     # MongoDB preset (95 LOC)
│           ├── nginx.cr                     # Nginx preset (37 LOC)
│           ├── rabbitmq.cr                  # RabbitMQ preset (92 LOC)
│           └── elasticsearch.cr             # Elasticsearch preset (60 LOC)
├── spec/
│   ├── spec_helper.cr                       # Spec configuration
│   ├── docker_container_spec.cr             # Core container tests (295 LOC)
│   ├── containers_spec.cr                   # Preset container tests (185 LOC)
│   ├── network_spec.cr                      # Network tests (35 LOC)
│   └── integration_spec.cr                  # Integration tests (115 LOC)
├── lib/                                     # Installed dependencies
├── README.md
├── QUICKSTART.md
├── ARCHITECTURE.md
├── CONTRIBUTING.md
├── PROJECT_SUMMARY.md
├── IMPLEMENTATION_GUIDE.md
├── CODE_OF_CONDUCT.md
├── AGENTS.md
├── LICENSE
└── .gitignore
```

## Key Features Implemented

### Container Lifecycle
- Create containers from Docker images with automatic image pulling
- Start, stop, restart, pause, unpause, kill, and remove containers
- Container state inspection: `running?`, `exited?`, `healthy?`, `exists?`
- Log retrieval and command execution (`exec`)
- Mapped port discovery after start

### Fluent Builder API
Every configuration method returns `self` for chaining:
- `with_name` — set container name
- `with_exposed_port` / `with_exposed_ports` — port binding
- `with_fixed_exposed_port` — specific host port binding
- `with_env` / `with_envs` — environment variables
- `with_label` / `with_labels` — container labels
- `with_cmd` — override CMD
- `with_entrypoint` — override ENTRYPOINT
- `with_working_dir` — set working directory
- `with_network` / `with_network_alias` — networking
- `with_healthcheck` — Docker healthcheck configuration
- `with_wait_for` — wait strategy selection

### Wait Strategies
| Strategy | Method | Mechanism |
|----------|--------|-----------|
| Log matching | `wait_for_logs` | Polls container logs for regex match |
| TCP port | `wait_for_tcp_port` | Attempts TCP connection to host:mappedPort |
| HTTP endpoint | `wait_for_http` | Polls HTTP GET for expected status code |
| Healthcheck | `wait_for_healthcheck` | Reads Docker HEALTHCHECK status |

All strategies use `Time.instant` for monotonic elapsed time and configurable timeout/interval.

### Networking
- `Network.create(name)` — create bridge network
- `Network.create(name) { |n| ... }` — block-based with auto-cleanup
- Container network aliases for DNS discovery

### Pre-configured Modules
8 service containers with sensible defaults:
- **PostgresContainer** — `postgres:latest`, port 5432, configurable DB/user/password
- **MySQLContainer** — `mysql:latest`, port 3306, configurable DB/user/password with root password
- **MariaDBContainer** — `mariadb:latest`, port 3306, configurable DB/user/password with root password
- **RedisContainer** — `redis:latest`, port 6379, optional password
- **MongoContainer** — `mongo:latest`, port 27017, optional auth
- **NginxContainer** — `nginx:latest`, port 80
- **RabbitMQContainer** — `rabbitmq:management`, ports 5672/15672, configurable user/password/vhost
- **ElasticsearchContainer** — `elasticsearch:8.11.0`, port 9200, security disabled by default

## Architecture Decisions

### Why Classes with Method Chaining
Crystal uses classes and modules rather than protocols. The fluent builder pattern uses method chaining via `self` returns:

```crystal
class DockerContainer
  def with_name(name : String) : self
    @name = name
    self
  end
end
```

### Why docr Over Raw HTTP
The `docr` shard provides a well-tested Docker API client with proper type mappings. Writing raw HTTP against the Docker socket would duplicate significant work.

### Why Singleton DockerClient
A single Docker connection is sufficient for test scenarios. The singleton pattern (`DockerClient.instance`) avoids creating multiple connections and keeps configuration centralized.

### Why Reference Types (Classes)
Containers are live external resources — shared references to the same container object are desirable. Lifecycle methods mutate internal state (container ID, mapped ports, status).

## Extending the Library

### Adding a New Service Module

```crystal
# src/testcontainers/containers/myservice.cr
module Testcontainers
  class MyServiceContainer < DockerContainer
    IMAGE = "myservice"
    PORT  = 9000

    def initialize(image = "#{IMAGE}:latest")
      super(image)
      with_exposed_port(PORT)
      with_env("CONFIG_KEY", "value")
      with_wait_for(:logs, message: /Service started/)
    end

    def with_config(value : String) : self
      with_env("CONFIG_KEY", value)
      self
    end

    def connection_url : String
      port = mapped_port(PORT)
      host = self.host
      "myservice://#{host}:#{port}"
    end
  end
end
```

Then add `require "./testcontainers/containers/myservice"` to `src/testcontainers.cr`.

### Adding a Custom Wait Strategy

Add a method to `DockerContainer`:

```crystal
def wait_for_custom(timeout : Int32 = 60, interval : Int32 = 1) : self
  @wait_strategies << {type: :custom, timeout: timeout, interval: interval}
  self
end

# In the private execute_wait_strategies method, add:
private def execute_custom_wait(timeout, interval)
  start_time = Time.instant
  loop do
    # Your custom readiness check
    break if container_is_ready?
    elapsed = Time.instant - start_time
    raise TimeoutError.new("Custom wait timed out") if elapsed.total_seconds >= timeout
    sleep interval.seconds
  end
end
```

## Testing

### Run Unit Tests
```bash
crystal spec
```

### Run Integration Tests (Docker required)
```bash
crystal spec -Dintegration
```

### Run Specific Spec File
```bash
crystal spec spec/docker_container_spec.cr
```

### Type-Check Without Running
```bash
crystal build --no-codegen spec/docker_container_spec.cr
```

## Dependencies

| Shard | Version | Purpose |
|-------|---------|---------|
| docr | ~> 0.1.4 | Docker Engine API client |
| crystar | 0.4.0 | Tar archive support (docr dependency) |

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | Tested |
| macOS (Intel) | Supported |
| Linux (x86_64) | Supported |
| Linux (aarch64) | Supported |

## Requirements

- **Crystal**: >= 1.10.0
- **Docker**: Docker or Docker Desktop running
- **OS**: macOS or Linux

## Getting Help

- **[QUICKSTART.md](QUICKSTART.md)** — Get running in 5 minutes
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Understand the design
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — How to contribute
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** — Feature inventory
- **GitHub Issues** — Report bugs or request features
