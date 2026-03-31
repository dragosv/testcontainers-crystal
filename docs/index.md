# Testcontainers for Crystal

Testcontainers for Crystal is a Crystal library that makes it simple to create and clean up container-based dependencies for automated integration and end-to-end tests. The library integrates with Crystal's built-in `spec` framework.

Typical use cases include spinning up throwaway instances of databases, message brokers, or any Docker image as part of your test suite — containers start in seconds and are cleaned up automatically when the test finishes.

```crystal title="Quickstart example"
require "testcontainers"

container = Testcontainers::DockerContainer.new("testcontainers/helloworld:1.3.0")
  .with_exposed_port(8080)
  .with_wait_for_http(path: "/uuid", container_port: 8080)

container.start

host = container.host
port = container.mapped_port(8080)

response = HTTP::Client.get("http://#{host}:#{port}/uuid")
puts "Received UUID: #{response.body}"

container.stop
container.remove
```

<p style="text-align:center">
  <strong>Not using Crystal? Here are other supported languages!</strong>
</p>
<div class="card-grid">
  <a class="card-grid-item" href="https://java.testcontainers.org">
    <img src="language-logos/java.svg" />Java
  </a>
  <a class="card-grid-item" href="https://golang.testcontainers.org">
    <img src="language-logos/go.svg" />Go
  </a>
  <a class="card-grid-item" href="https://dotnet.testcontainers.org">
    <img src="language-logos/dotnet.svg" />.NET
  </a>
  <a class="card-grid-item" href="https://node.testcontainers.org">
    <img src="language-logos/nodejs.svg" />Node.js
  </a>
  <a class="card-grid-item" href="https://testcontainers-python.readthedocs.io/en/latest/">
    <img src="language-logos/python.svg" />Python
  </a>
  <a class="card-grid-item" href="https://docs.rs/testcontainers/latest/testcontainers/">
    <img src="language-logos/rust.svg" />Rust
  </a>
  <a class="card-grid-item" href="https://github.com/testcontainers/testcontainers-hs/">
    <img src="language-logos/haskell.svg"/>Haskell
  </a>
  <a href="https://github.com/testcontainers/testcontainers-ruby/" class="card-grid-item"><img src="language-logos/ruby.svg"/>Ruby</a>
</div>

## About

Testcontainers for Crystal is a Crystal library to support tests with throwaway instances of Docker containers. It uses [docr](https://github.com/marghidanu/docr) as the low-level Docker Engine API client, communicating with Docker via the Docker Remote API over Unix sockets. It provides a lightweight, type-safe implementation to support your test environment.

Choose from existing pre-configured [modules](modules/index.md) — PostgreSQL, MySQL, Redis, and MongoDB — and start containers within seconds. Or use the generic `DockerContainer` to run any Docker image with full control over configuration.

Read the [Quickstart](quickstart/index.md) to get up and running in minutes.

## System requirements

Please read the [System Requirements](system_requirements/index.md) page before you start.

| Requirement     | Minimum version      |
|-----------------|----------------------|
| Crystal         | 1.10.0               |
| macOS / Linux   | Any supported        |
| Docker          | 20.10+               |

Testcontainers automatically detects the Docker socket. It checks the `DOCKER_HOST` environment variable first, then `~/.docker/run/docker.sock` (Docker Desktop on macOS), and finally `/var/run/docker.sock`.

## License

See [LICENSE](https://github.com/testcontainers/testcontainers-crystal/blob/main/LICENSE).

## Copyright

Copyright (c) 2024 - 2026 The Testcontainers for Crystal Authors.

----

Join our [Slack workspace](https://slack.testcontainers.org/) | [Testcontainers OSS](https://www.testcontainers.org/) | [Testcontainers Cloud](https://testcontainers.com/cloud/)
[testcontainers-cloud]: https://www.testcontainers.cloud/
