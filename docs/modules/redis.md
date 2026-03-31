# Redis

## Introduction

The Testcontainers module for Redis provides a pre-configured container for running a Redis instance in your tests. It uses the official [`redis`](https://hub.docker.com/_/redis) Docker image.

Redis is the simplest module — it requires no credentials or database configuration by default.

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

container = Testcontainers::RedisContainer.new

begin
  container.start

  url = container.redis_url
  # url: "redis://localhost:XXXXX/0"

  # Use url with your Redis client
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

<!--/codeinclude-->

## Module Reference

### `RedisContainer`

The `RedisContainer` class configures and starts a Redis instance.

#### Initializer

```crystal
Testcontainers::RedisContainer.new(image : String = "redis:latest")
```

Creates a new Redis container with the given image. The container is pre-configured with:

- **Image**: `redis:latest` (or custom)
- **Port**: `6379` (mapped to a random host port)

#### Container Options

| Method          | Type     | Default | Description                            |
|-----------------|----------|:-------:|----------------------------------------|
| `with_password` | `String` | `nil`   | Sets a password for Redis AUTH         |

#### Wait Strategy

The module uses a log-based wait strategy (applied automatically):

| Strategy | Configuration |
|----------|---------------|
| Log      | `/Ready to accept connections/` |

#### Start

```crystal
container.start : self
```

Starts the container and returns `self` for method chaining.

#### Properties

| Property    | Type      | Description                       |
|-------------|-----------|-----------------------------------|
| `password`  | `String?` | The configured password (if any)  |

#### Methods

| Method       | Return Type | Description                         |
|--------------|-------------|-------------------------------------|
| `redis_url`  | `String`    | Returns a `redis://` connection URI |
| `database_url` | `String` | Alias for `redis_url`               |
| `stop`       | `self`      | Stops the container                 |
| `remove`     | `self`      | Removes the container               |

##### Connection URL format

```
redis://<host>:<mapped-port>/0
redis://:<password>@<host>:<mapped-port>/0
```

## Examples

### Default configuration

```crystal
container = Testcontainers::RedisContainer.new
container.start
url = container.redis_url
# "redis://localhost:XXXXX/0"
```

### Pinned version

```crystal
container = Testcontainers::RedisContainer.new("redis:7")
container.start
url = container.redis_url
```

### With password

```crystal
container = Testcontainers::RedisContainer.new
  .with_password("secret")
container.start
url = container.redis_url
# "redis://:secret@localhost:XXXXX/0"
```

### Using begin/ensure cleanup

```crystal
container = Testcontainers::RedisContainer.new

begin
  container.start

  url = container.redis_url
  # Connect your Redis client to url
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```
