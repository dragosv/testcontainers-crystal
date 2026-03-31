# MongoDB

## Introduction

The Testcontainers module for MongoDB provides a pre-configured container for running a MongoDB instance in your tests. It uses the official [`mongo`](https://hub.docker.com/_/mongo) Docker image.

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

container = Testcontainers::MongoContainer.new
  .with_username("testuser")
  .with_password("testpass")

begin
  container.start

  url = container.connection_url
  # url: "mongodb://testuser:testpass@localhost:XXXXX/test"

  # Use url with your MongoDB driver
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

<!--/codeinclude-->

## Module Reference

### `MongoContainer`

The `MongoContainer` class configures and starts a MongoDB instance.

#### Initializer

```crystal
Testcontainers::MongoContainer.new(image : String = "mongo:latest")
```

Creates a new MongoDB container with the given image. The container is pre-configured with:

- **Image**: `mongo:latest` (or custom)
- **Port**: `27017` (mapped to a random host port)
- **Default credentials**: no username/password by default
- **Default database**: `test`

#### Container Options

| Method           | Type     | Default  | Description                                  |
|------------------|----------|:--------:|----------------------------------------------|
| `with_username`  | `String` | `nil`    | Sets the `MONGO_INITDB_ROOT_USERNAME` env var |
| `with_password`  | `String` | `nil`    | Sets the `MONGO_INITDB_ROOT_PASSWORD` env var |
| `with_database`  | `String` | `"test"` | Sets the `MONGO_INITDB_DATABASE` env var     |

All option methods return `self` for fluent chaining.

#### Wait Strategy

The module uses a log-based wait strategy (applied automatically):

| Strategy | Configuration |
|----------|---------------|
| Log      | `/Waiting for connections\|ready for connections/` |

#### Start

```crystal
container.start : self
```

Starts the container and returns `self` for method chaining.

#### Properties

| Property    | Type      | Description                       |
|-------------|-----------|-----------------------------------|
| `username`  | `String?` | The configured username           |
| `password`  | `String?` | The configured password           |
| `database`  | `String`  | The configured database name      |

#### Methods

| Method           | Return Type | Description                             |
|------------------|-------------|-----------------------------------------|
| `connection_url` | `String`    | Returns a `mongodb://` connection URI   |
| `database_url`   | `String`    | Alias for `connection_url`              |
| `stop`           | `self`      | Stops the container                     |
| `remove`         | `self`      | Removes the container                   |

##### Connection string format

```
mongodb://<username>:<password>@<host>:<mapped-port>/<database>
mongodb://<host>:<mapped-port>/<database>
```

## Examples

### Default configuration

```crystal
container = Testcontainers::MongoContainer.new
container.start
url = container.connection_url
# "mongodb://localhost:XXXXX/test"
```

### Pinned version

```crystal
container = Testcontainers::MongoContainer.new("mongo:7")
  .with_username("myuser")
  .with_password("mypass")
container.start
```

### Connecting to a specific database

```crystal
container = Testcontainers::MongoContainer.new
  .with_database("myDatabase")
container.start
url = container.connection_url
# "mongodb://localhost:XXXXX/myDatabase"
```
