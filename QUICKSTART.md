# Quick Start Guide

Get started with Testcontainers for Crystal in 5 minutes.

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  testcontainers:
    github: dragosv/testcontainers-crystal
    version: "~> 0.1.0"
```

Then install:

```bash
shards install
```

## Prerequisites

- Crystal >= 1.10.0
- Docker or Docker Desktop running

Verify Docker is running:

```bash
docker ps
```

## Basic Example

```crystal
require "testcontainers"

# Create and start a PostgreSQL container
pg = Testcontainers::PostgresContainer.new
  .with_database("mydb")
  .with_username("user")
  .with_password("password")
  .start

# Use the connection string
url = pg.connection_url
puts "Connected to: #{url}"

# Clean up
pg.stop
pg.remove
```

## Starting a Custom Container

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("nginx:latest")
  .with_name("my-web-server")
  .with_exposed_port(80)
  .with_wait_for(:http, port: 80)
  .start

port = container.mapped_port(80)
puts "Nginx running at http://localhost:#{port}"

container.stop
container.remove
```

## Using with Crystal Spec

```crystal
require "spec"
require "testcontainers"

describe "Database tests" do
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

## Available Modules

### PostgreSQL

```crystal
pg = Testcontainers::PostgresContainer.new("postgres:15")
  .with_database("testdb")
  .start

url = pg.connection_url
```

### MySQL

```crystal
mysql = Testcontainers::MySQLContainer.new("mysql:8.0")
  .with_database("testdb")
  .start

url = mysql.connection_url
```

### MariaDB

```crystal
mariadb = Testcontainers::MariaDBContainer.new("mariadb:11")
  .with_database("testdb")
  .start

url = mariadb.connection_url
```

### Redis

```crystal
redis = Testcontainers::RedisContainer.new("redis:7")
  .start

url = redis.connection_url
```

### MongoDB

```crystal
mongo = Testcontainers::MongoContainer.new("mongo:6.0")
  .start

url = mongo.connection_url
```

### RabbitMQ

```crystal
rabbit = Testcontainers::RabbitMQContainer.new
  .start

amqp_url = rabbit.connection_url
mgmt_url = rabbit.management_url
```

### Nginx

```crystal
nginx = Testcontainers::NginxContainer.new
  .start

base = nginx.base_url
```

### Elasticsearch

```crystal
es = Testcontainers::ElasticsearchContainer.new
  .start

url = es.connection_url
```

## Common Patterns

### Using ensure for cleanup

```crystal
container = Testcontainers::DockerContainer.new("redis:latest")
  .with_exposed_port(6379)
  .start

begin
  # Use container...
  port = container.mapped_port(6379)
ensure
  container.stop
  container.remove
end
```

### Custom wait strategies

```crystal
container = Testcontainers::DockerContainer.new("postgres:15")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "secret")
  .with_wait_for(:logs, message: /ready to accept connections/)
  .start
```

### Environment variables

```crystal
container = Testcontainers::DockerContainer.new("postgres:15")
  .with_env("POSTGRES_DB", "testdb")
  .with_env("POSTGRES_USER", "testuser")
  .with_env("POSTGRES_PASSWORD", "testpass")
  .with_exposed_port(5432)
  .start
```

### Network communication

```crystal
Testcontainers::Network.create("app-network") do |network|
  db = Testcontainers::PostgresContainer.new
    .with_network(network)
    .with_network_alias("database")
    .start

  app = Testcontainers::DockerContainer.new("myapp:latest")
    .with_network(network)
    .with_env("DB_HOST", "database")
    .start

  # "app" can reach "db" at hostname "database"

  app.stop; app.remove
  db.stop; db.remove
end
# Network is automatically cleaned up
```

### Healthcheck configuration

```crystal
container = Testcontainers::DockerContainer.new("postgres:15")
  .with_exposed_port(5432)
  .with_env("POSTGRES_PASSWORD", "secret")
  .with_healthcheck(
    test: ["CMD-SHELL", "pg_isready -U postgres"],
    interval: 1.seconds,
    timeout: 5.seconds,
    retries: 10
  )
  .with_wait_for(:healthcheck)
  .start
```

## Troubleshooting

### Docker not running

**Error**: Connection refused or socket not found

**Solution**: Ensure Docker is installed and running:
```bash
docker ps
```

### Port already in use

**Solution**: The library assigns random host ports by default. If you need a specific port, ensure it is free before starting the container.

### Slow image pulls

First-time container starts may be slow due to image downloads. Subsequent runs use cached images.
