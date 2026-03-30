# MySQL

## Introduction

The Testcontainers module for MySQL provides a pre-configured container for running a MySQL database instance in your tests. It uses the official [`mysql`](https://hub.docker.com/_/mysql) Docker image.

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

container = Testcontainers::MysqlContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

begin
  container.start

  url = container.database_url
  # url: "mysql://admin:secret@localhost:XXXXX/testdb"

  # Use url with your MySQL driver
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

<!--/codeinclude-->

## Module Reference

### `MysqlContainer`

The `MysqlContainer` class configures and starts a MySQL instance.

#### Initializer

```crystal
Testcontainers::MysqlContainer.new(image : String = "mysql:latest")
```

Creates a new MySQL container with the given image. The container is pre-configured with:

- **Image**: `mysql:latest` (or custom)
- **Port**: `3306` (mapped to a random host port)
- **Default credentials**: root_password `test`, username `test`, password `test`, database `test`
- **Healthcheck**: `mysqladmin ping -h localhost`

#### Container Options

| Method               | Type     | Default  | Description                            |
|----------------------|----------|:--------:|----------------------------------------|
| `with_database`      | `String` | `"test"` | Sets the `MYSQL_DATABASE` env var      |
| `with_username`      | `String` | `"test"` | Sets the `MYSQL_USER` env var          |
| `with_password`      | `String` | `"test"` | Sets the `MYSQL_PASSWORD` env var      |
| `with_root_password` | `String` | `"test"` | Sets the `MYSQL_ROOT_PASSWORD` env var |

All option methods return `self` for fluent chaining.

#### Wait Strategy

The module uses a healthcheck-based wait strategy (applied automatically):

| Strategy    | Configuration |
|-------------|---------------|
| Healthcheck | `mysqladmin ping -h localhost` (shell mode) |

#### Start

```crystal
container.start : self
```

Starts the container and returns `self` for method chaining.

#### Properties

| Property        | Type     | Description                       |
|-----------------|----------|-----------------------------------|
| `root_password` | `String` | The configured root password      |
| `username`      | `String` | The configured username           |
| `password`      | `String` | The configured password           |
| `database`      | `String` | The configured database name      |

#### Methods

| Method         | Return Type | Description                            |
|----------------|-------------|----------------------------------------|
| `database_url` | `String`    | Returns a `mysql://` connection URI    |
| `stop`         | `self`      | Stops the container                    |
| `remove`       | `self`      | Removes the container                  |

##### Connection string format

```
mysql://<username>:<password>@<host>:<mapped-port>/<database>
```

## Examples

### Default configuration

```crystal
container = Testcontainers::MysqlContainer.new
container.start
url = container.database_url
# "mysql://test:test@localhost:XXXXX/test"
```

### Pinned version

```crystal
container = Testcontainers::MysqlContainer.new("mysql:8.0")
  .with_database("mydb")
  .with_username("user1")
  .with_password("pass1")
container.start
```

### Custom root password

```crystal
container = Testcontainers::MysqlContainer.new
  .with_root_password("strongpassword")
container.start

url = container.database_url
# "mysql://test:test@localhost:XXXXX/test"
```
