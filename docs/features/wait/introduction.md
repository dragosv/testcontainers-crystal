# Wait strategies — Introduction

Wait strategies detect when a container is ready for testing. They check different indicators of readiness and complete as soon as they are fulfilled. By default, Testcontainers will proceed without waiting. For most images, you should configure a wait strategy to ensure the service is fully ready before running tests.

## Available strategies

| Strategy                                  | Description                                                           |
|-------------------------------------------|-----------------------------------------------------------------------|
| [HTTP](#wait-for-http)                    | Waits for an HTTP endpoint to return a 2xx status code.               |
| [TCP](#wait-for-tcp)                      | Waits for a TCP port to be reachable.                                 |
| [Log](#wait-for-log)                      | Waits for a specific message in the container logs.                   |
| [Health check](#wait-for-health-check)    | Waits for Docker's HEALTHCHECK to report healthy.                     |
| [Combined](#combining-strategies)         | Waits for multiple strategies to all succeed.                         |

## Startup timeout

Each wait strategy supports a configurable timeout. The default timeout is **60 seconds**. If the strategy does not succeed within the timeout, a `Testcontainers::ContainerStartupError` is raised.

```crystal
# Wait up to 2 minutes for logs
container.with_wait_for_logs(/Server started/, timeout: 120)
```

## Setting a wait strategy

Wait strategies are set as chainable methods on `DockerContainer`:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "password")
  .with_wait_for_tcp_port(5432)
  .with_wait_for_logs(/database system is ready to accept connections/)
  .start
```

Multiple wait strategies can be chained — they are executed sequentially.

## Wait for HTTP

The HTTP wait strategy checks if an HTTP endpoint returns a successful response (status code 2xx). You can configure the port, path, and timeout.

```crystal
# Basic — wait for port 8080 to respond with 2xx on "/"
container.with_wait_for_http(port: 8080)

# Custom path and timeout
container.with_wait_for_http(port: 443, path: "/health", timeout: 120)
```

**Parameters:**

| Parameter  | Default | Description                          |
|------------|---------|--------------------------------------|
| `port`     | —       | The container port to check.         |
| `path`     | `"/"`   | The HTTP path to request.            |
| `timeout`  | `60`    | Maximum seconds to wait.             |

**Example:**

```crystal
container = Testcontainers::DockerContainer.new("httpbin/httpbin:latest")
  .with_exposed_port(80)
  .with_wait_for_http(port: 80, path: "/uuid")
  .start
```

## Wait for TCP

The TCP wait strategy checks if a TCP port is reachable on the container. This verifies that a service is listening on the specified port.

```crystal
container.with_wait_for_tcp_port(5432)
container.with_wait_for_tcp_port(5432, timeout: 120)
```

**Parameters:**

| Parameter  | Default | Description                          |
|------------|---------|--------------------------------------|
| `port`     | —       | The container port to check.         |
| `timeout`  | `60`    | Maximum seconds to wait.             |

!!! note

    Just because a service is listening on a TCP port does not necessarily mean it is fully ready to handle requests. Log-based or HTTP-based strategies often provide more reliable readiness confirmation.

## Wait for log

The log wait strategy monitors the container's stdout/stderr and completes when a specific message appears.

```crystal
container.with_wait_for_logs(/database system is ready to accept connections/)
container.with_wait_for_logs(/Ready to accept connections/, timeout: 120)
```

**Parameters:**

| Parameter  | Default | Description                            |
|------------|---------|----------------------------------------|
| `matcher`  | —       | A `Regex` to match against log output. |
| `timeout`  | `60`    | Maximum seconds to wait.               |

## Wait for health check

If the Docker image has a [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) instruction, you can wait for Docker to report the container as healthy:

```crystal
container.with_wait_for_healthcheck
container.with_wait_for_healthcheck(timeout: 120)
```

**Parameters:**

| Parameter  | Default | Description                          |
|------------|---------|--------------------------------------|
| `timeout`  | `60`    | Maximum seconds to wait.             |

## Combining strategies

Chain multiple `with_wait_for_*` methods to combine wait strategies. All strategies must succeed for the container to be considered ready:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "password")
  .with_wait_for_tcp_port(5432)
  .with_wait_for_logs(/database system is ready to accept connections/)
  .start
```

Strategies are executed sequentially in the order they are chained.

## Pre-configured modules

The pre-configured container modules (e.g., `PostgresContainer`, `RedisContainer`) already include appropriate wait strategies. You typically do not need to set a wait strategy when using a module:

```crystal
# PostgresContainer uses a healthcheck wait strategy by default
container = Testcontainers::PostgresContainer.new.start
```

## Summary

| Factory method          | Description                                                           |
|-------------------------|-----------------------------------------------------------------------|
| `Wait.noWait()`         | No waiting, proceeds immediately.                                     |
| `Wait.http(...)`        | Waits for an HTTP endpoint to return a 2xx status code.               |
| `Wait.tcp(...)`         | Waits for a TCP port to be reachable.                                 |
| `Wait.log(...)`         | Waits for a specific message in the container logs.                   |
| `Wait.exec(...)`        | Waits for a command to execute successfully inside the container.     |
| `Wait.healthCheck(...)` | Waits for Docker's built-in health check to report healthy.           |
| `Wait.all(...)`         | Combines multiple wait strategies; all must succeed.                  |
| `CustomWaitStrategy`    | Allows custom readiness logic via a closure.                          |
