# AGENTS.md

Guidelines for AI agents working in the **testcontainers-crystal** repository.

## Project Overview

Crystal library for managing throwaway Docker containers in tests, inspired by [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby). Uses [docr](https://github.com/marghidanu/docr) as the low-level Docker Engine API client. Provides a fluent builder API, multiple wait strategies, and pre-configured modules for common services.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and component diagrams.
See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for a full feature inventory.

## Build & Test

```bash
shards install       # Install dependencies
crystal build        # Build all targets
crystal spec         # Run the full test suite (unit tests, Docker not required)
crystal spec -Dintegration  # Run integration tests (requires Docker running)
```

## Code Style

- Crystal >= 1.10.0, Shards for dependency management.
- 2-space indentation, ~120-character line limit.
- `PascalCase` for types, `snake_case` for methods/variables.
- All public APIs should have `#` doc comments.
- Use method chaining on builder-style methods that return `self`.
- Use fibers and `sleep` for async I/O patterns. Never use callbacks.
- Follow the rules in [CONTRIBUTING.md](CONTRIBUTING.md) for commit messages and PR conventions.

## Architecture Rules

- **Single module**: `Testcontainers` wraps `docr` (the Docker client). `docr` must not be patched beyond minimal compatibility fixes (see `patches.cr`).
- **Classes with method chaining**: `DockerContainer` is the core class with a fluent builder API.
- **Container presets**: Pre-configured container classes (e.g. `Testcontainers::PostgresContainer`) inherit common patterns, set default image/port/env, and expose `connection_url` helpers.
- **Strategy pattern for readiness**: wait strategies (`wait_for_logs`, `wait_for_tcp_port`, `wait_for_healthcheck`, `wait_for_http`) are composable methods on `DockerContainer`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and rationale.

## Key Paths

| Area | Path |
|------|------|
| Shard manifest | `shard.yml` |
| Main entry point | `src/testcontainers.cr` |
| Core container class | `src/testcontainers/docker_container.cr` |
| Docker client wrapper | `src/testcontainers/docker_client.cr` |
| Pre-configured modules | `src/testcontainers/containers/` |
| Wait strategies | Built into `docker_container.cr` |
| Network management | `src/testcontainers/network.cr` |
| Error types | `src/testcontainers/errors.cr` |
| Docr patches | `src/testcontainers/patches.cr` |
| Unit tests | `spec/docker_container_spec.cr`, `spec/containers_spec.cr`, `spec/network_spec.cr` |
| Integration tests | `spec/integration_spec.cr` |

## Common Agent Tasks

### Adding a new container module

1. Create a new file in `src/testcontainers/containers/`, following the existing `postgres.cr` / `redis.cr` pattern.
2. Pre-configure: image, default port, environment variables, and a wait strategy.
3. Expose a `connection_url` (or equivalent) method.
4. Require the new file in `src/testcontainers.cr`.
5. Add unit tests in `spec/containers_spec.cr`.

### Adding a new wait strategy

1. Add a new `wait_for_*` method on `DockerContainer` in `src/testcontainers/docker_container.cr`.
2. Implement with timeout + retry loop using `Time.instant` for elapsed time tracking.
3. Add a test exercising the new strategy.

### Updating dependencies

Dependencies are managed via `shard.yml`. Run `shards install` after changes.

## Testing Expectations

- Every new public API must have at least one test.
- Tests use Crystal's built-in `spec` framework.
- Unit tests mock Docker interactions and do not require Docker running.
- Integration tests (behind `-Dintegration` flag) require Docker.
- Always clean up containers in tests with `ensure` or equivalent.

## Additional Best Practices

- Prefer explicit nil checks over `not_nil!`; avoid `as` casts in production paths.
- Propagate exceptions; only rescue in top-level cleanup code.
- Use `begin/ensure` blocks for resource cleanup.
- Keep Docker endpoint configuration centralized via `Testcontainers::DockerClient`.
- When adding monkey-patches to `docr` types, isolate them in `patches.cr` with clear comments.
