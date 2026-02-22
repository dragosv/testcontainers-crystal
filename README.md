[![Crystal](https://img.shields.io/badge/Crystal-%3E%3D%201.10.0-blue.svg)](https://crystal-lang.org)
[![Docker](https://img.shields.io/badge/Docker%20Engine%20API-blue)](https://docs.docker.com/engine/api/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# Testcontainers for Crystal

A lightweight Crystal library for writing tests with throwaway Docker containers, inspired by [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby). Uses [docr](https://github.com/marghidanu/docr) for Docker Engine API communication.

## Requirements

- Crystal >= 1.10.0
- Docker or Docker Desktop running

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  testcontainers:
    github: dragosv/testcontainers-crystal
    version: "~> 0.1.0"
```

Then run:

```bash
shards install
```

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for a step-by-step guide.

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("nginx:latest")
  .with_exposed_port(80)
  .with_wait_for(:http, port: 80)
  .start

port = container.mapped_port(80)
puts "Nginx running at http://localhost:#{port}"

container.stop
container.remove
```

## Modules

Pre-configured containers for common services — each exposes a `connection_url` convenience method:

| Module | Image | Default Port |
|--------|-------|-------------|
| `PostgresContainer` | `postgres` | 5432 |
| `MySQLContainer` | `mysql` | 3306 |
| `MariaDBContainer` | `mariadb` | 3306 |
| `RedisContainer` | `redis` | 6379 |
| `MongoContainer` | `mongo` | 27017 |
| `NginxContainer` | `nginx` | 80 |
| `RabbitMQContainer` | `rabbitmq` | 5672 / 15672 |
| `ElasticsearchContainer` | `elasticsearch` | 9200 |

```crystal
pg = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .start

url = pg.connection_url
```

## Wait Strategies

```crystal
# Wait for log message matching a regex
.with_wait_for(:logs, message: /ready to accept connections/)

# Wait for a TCP port to be reachable
.with_wait_for(:tcp, port: 5432)

# Wait for an HTTP endpoint to return 200
.with_wait_for(:http, port: 8080, path: "/health")

# Wait for Docker HEALTHCHECK to report healthy
.with_wait_for(:healthcheck)
```

## Crystal Spec Integration

```crystal
require "spec"
require "testcontainers"

describe "Database" do
  it "connects to PostgreSQL" do
    pg = Testcontainers::PostgresContainer.new
      .with_database("testdb")
      .start

    begin
      url = pg.connection_url
      url.should contain("postgres://")
    ensure
      pg.stop
      pg.remove
    end
  end
end
```

## Networking

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

## Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute getting-started guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Design decisions and component overview |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Detailed implementation guide |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Full feature inventory and stats |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |

## Contributing

Contributions are welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## Acknowledgments

- [testcontainers-ruby](https://github.com/testcontainers/testcontainers-ruby) — Reference implementation
- [docr](https://github.com/marghidanu/docr) — Crystal Docker client

## License

MIT — see [LICENSE](LICENSE).

## Support

[GitHub Issues](https://github.com/dragosv/testcontainers-crystal/issues) · [Testcontainers Slack](https://slack.testcontainers.org/)
