# PostgreSQL

## Introduction

The Testcontainers module for PostgreSQL provides a pre-configured container for running a PostgreSQL database instance in your tests. It uses the official [`postgres`](https://hub.docker.com/_/postgres) Docker image.

## Adding the dependency

Add Testcontainers to your `shard.yml`:

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

## Usage example

<!--codeinclude-->

```crystal
require "testcontainers"

container = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

begin
  container.start

  url = container.database_url
  # url: "postgres://admin:secret@localhost:XXXXX/testdb"

  # Use url with your PostgreSQL driver
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

<!--/codeinclude-->

## Module Reference

### `PostgresContainer`

The `PostgresContainer` class configures and starts a PostgreSQL instance.

#### Initializer

```crystal
Testcontainers::PostgresContainer.new(image : String = "postgres:latest")
```

Creates a new PostgreSQL container with the given image. The container is pre-configured with:

- **Image**: `postgres:latest` (or custom)
- **Port**: `5432` (mapped to a random host port)
- **Default credentials**: username `test`, password `test`, database `test`
- **Healthcheck**: `pg_isready` command

#### Container Options

| Method            | Type     | Default  | Description                       |
|-------------------|----------|:--------:|-----------------------------------|
| `with_database`   | `String` | `"test"` | Sets the `POSTGRES_DB` env var    |
| `with_username`   | `String` | `"test"` | Sets the `POSTGRES_USER` env var  |
| `with_password`   | `String` | `"test"` | Sets the `POSTGRES_PASSWORD` env var |

All option methods return `self` for fluent chaining.

#### Wait Strategy

The module uses a healthcheck-based wait strategy (applied automatically):

| Strategy    | Configuration |
|-------------|---------------|
| Healthcheck | `pg_isready -U <username> -d <database>` |

#### Start

```crystal
container.start : self
```

Starts the container and returns `self` for method chaining.

#### Properties

| Property    | Type      | Description                       |
|-------------|-----------|-----------------------------------|
| `username`  | `String`  | The configured username           |
| `password`  | `String`  | The configured password           |
| `database`  | `String`  | The configured database name      |

#### Methods

| Method           | Return Type | Description                               |
|------------------|-------------|-------------------------------------------|
| `database_url`   | `String`    | Returns a `postgres://` connection URI    |
| `stop`           | `self`      | Stops the container                       |
| `remove`         | `self`      | Removes the container                     |

##### Connection string format

```
postgres://<username>:<password>@<host>:<mapped-port>/<database>
```

## Examples

### Default configuration

```crystal
container = Testcontainers::PostgresContainer.new
container.start
url = container.database_url
# "postgres://test:test@localhost:XXXXX/test"
```

### Pinned version

```crystal
container = Testcontainers::PostgresContainer.new("postgres:16")
  .with_database("mydb")
  .with_username("user1")
  .with_password("pass1")
container.start
```

### Using a custom network

```crystal
network = Testcontainers::Network.new(name: "pg-net")
network.create!

container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "postgres")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)

container.start

host = container.host
port = container.mapped_port(5432)
url = "postgres://postgres:postgres@#{host}:#{port}/postgres"
```
