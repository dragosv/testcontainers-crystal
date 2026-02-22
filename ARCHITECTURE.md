# Testcontainers Crystal — Architecture

This document describes the internal design and architectural decisions of the library.
For a feature inventory and implementation stats see [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md).
For usage examples and getting-started instructions see [QUICKSTART.md](QUICKSTART.md).

## Design Goals

| Goal | Approach |
|------|----------|
| Crystal-first | Idiomatic Crystal classes, method chaining, blocks, and fibers |
| Type safety | Crystal's static type system enforces container configuration correctness |
| Developer experience | Fluent builder API, composable wait strategies |
| Minimal coupling | Thin wrapper over `docr`; only `patches.cr` touches upstream types |
| Testability | Unit tests run without Docker via mocked state |

## Module Structure

The library is a single Crystal shard that wraps the `docr` Docker client:

```
Testcontainers  ──uses──►  docr (Docr::API)  ──speaks to──►  Docker Engine
(high-level API)           (Docker HTTP client)               (REST API via Unix socket)
```

**docr** is an external Crystal shard providing low-level Docker Engine API access. It communicates over a Unix socket (`/var/run/docker.sock`) and handles JSON serialization of Docker types.

**Testcontainers** owns all concepts meaningful to test authors: container lifecycle, wait strategies, pre-configured modules, network management, and the fluent builder API. It delegates all Docker I/O to `docr`.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Testcontainers module                                          │
│                                                                 │
│  ┌─────────────┐  configures  ┌─────────────────────────────┐  │
│  │  Preset     │────────────► │  DockerContainer             │  │
│  │  Containers │              │  (fluent builder API:         │  │
│  │  (Postgres, │              │   with_exposed_port,          │  │
│  │   MySQL,    │              │   with_env, with_name,        │  │
│  │   Redis,    │              │   with_cmd, etc.)             │  │
│  │   Mongo,    │              └──────────┬──────────────────┘  │
│  │   Nginx,    │                         │ lifecycle            │
│  │   RabbitMQ, │                         │ (start/stop/remove)  │
│  │   MariaDB,  │                         │                      │
│  │   Elastic)  │                         │                      │
│  └─────────────┘                         │                      │
│                                          │                      │
│  ┌──────────────────┐                    │                      │
│  │  Wait Strategies │◄───────────────────┤                      │
│  │  (wait_for_logs, │                    │                      │
│  │   wait_for_tcp,  │                    │                      │
│  │   wait_for_http, │                    │                      │
│  │   wait_for_      │                    │                      │
│  │   healthcheck)   │                    │                      │
│  └──────────────────┘                    │                      │
│                                          │                      │
│  ┌──────────────────┐                    │                      │
│  │  Network         │◄───────────────────┘                      │
│  │  (create/remove/ │                                           │
│  │   block-based)   │                                           │
│  └──────────────────┘                                           │
│                    │ delegates all Docker I/O                   │
└────────────────────┼────────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  docr shard (Docr::API)                                         │
│                                                                 │
│  Containers  ──►  create, start, stop, remove, inspect, exec   │
│  Images      ──►  create (pull)                                 │
│  Networks    ──►  create, remove                                │
│  All via Unix socket (/var/run/docker.sock)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Patterns

### 1. Fluent Builder (Method Chaining)

`DockerContainer` accumulates configuration through methods that return `self`, enabling natural chaining:

```crystal
container = Testcontainers::DockerContainer.new("postgres:15")
  .with_name("test-pg")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "secret")
  .with_wait_for(:logs, message: /ready to accept connections/)
```

Configuration is stored internally and applied when `.start` is called, which triggers image pull, container creation, start, and wait strategy execution.

### 2. Preset Container Pattern

Pre-configured containers set sensible defaults and expose domain-specific helpers:

```crystal
# PostgresContainer sets image, port 5432, env vars, and a log-based wait strategy
pg = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .with_username("myuser")
  .with_password("mypass")
  .start

url = pg.connection_url  # => "postgres://myuser:mypass@localhost:32768/testdb"
```

Each preset container is a subclass-like pattern that delegates to `DockerContainer` while adding service-specific methods.

### 3. Strategy Pattern for Readiness

Wait strategies are built into `DockerContainer` as composable methods:

| Strategy | Method | Mechanism |
|----------|--------|-----------|
| Log matching | `wait_for_logs` | Polls container logs for a regex match |
| TCP port | `wait_for_tcp_port` | Attempts TCP connection to mapped port |
| HTTP endpoint | `wait_for_http` | Polls HTTP endpoint for expected status |
| Health check | `wait_for_healthcheck` | Reads Docker health-check status |

All strategies share the same timeout + retry loop pattern using `Time.instant` for monotonic elapsed time tracking and configurable intervals.

### 4. Reference Types for Lifecycle Management

`DockerContainer` is a class, not a struct. This is intentional:

- A container is a live external resource — shared references to the same object are desirable.
- Lifecycle methods (`start`, `stop`, `remove`) mutate internal state (container ID, mapped ports, status).
- The Docker client is a singleton managing a shared connection.

### 5. Network Isolation

`Testcontainers::Network` manages Docker bridge networks:

```crystal
Testcontainers::Network.create("test-net") do |network|
  container = Testcontainers::DockerContainer.new("nginx:latest")
    .with_network(network)
    .with_network_alias("web")
    .start
  # Container is reachable at hostname "web" within the network
end
# Network is automatically removed when the block exits
```

## Docker Client Wrapper

`Testcontainers::DockerClient` is a singleton wrapper around `Docr::API`:

```crystal
client = Testcontainers::DockerClient.instance
```

Host resolution order:
1. `TC_HOST` environment variable
2. `DOCKER_HOST` environment variable
3. `localhost` (default, via Unix socket)

The client is used internally by `DockerContainer` and `Network`. End users typically interact only with container classes.

## Error Model

`Testcontainers` defines a hierarchy of exception classes:

```crystal
Testcontainers::TestcontainersError          # Base error
Testcontainers::ConnectionError              # Docker connection failure
Testcontainers::ContainerNotStartedError     # Operation on unstarted container
Testcontainers::TimeoutError                 # Wait strategy timeout
Testcontainers::PortNotMappedError           # Missing port mapping
Testcontainers::ContainerStartError          # Container failed to start
Testcontainers::ImagePullError               # Image pull failure
```

## Port Mapping

When ports are exposed via `with_exposed_port`, the Docker Engine allocates a random host port. After container start, the library inspects the container to discover the actual mapping. `mapped_port(container_port)` returns the host port.

Ports are stored internally in Docker's `"port/tcp"` format.

## Docr Patches

The `patches.cr` file contains minimal monkey-patches to fix compatibility issues with the `docr` shard:

- `Docr::Types::ExecConfig` — adds missing `include JSON::Serializable` annotation required for JSON serialization during `exec` operations.

These patches are isolated and clearly documented. The goal is upstream contribution or removal when docr is updated.

## References

- [Docker Engine API](https://docs.docker.com/engine/api/)
- [docr — Crystal Docker client](https://github.com/marghidanu/docr)
- [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby) — reference implementation
- [Crystal Language](https://crystal-lang.org/reference/)
