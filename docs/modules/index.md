# Testcontainers for Crystal modules

In this section you'll find documentation for the pre-configured container modules available in Testcontainers for Crystal. Each module provides sensible defaults for a specific technology — image, ports, environment variables, and wait strategies — so you can get started with minimal configuration.

## Available modules

| Module                              | Default Image   | Default Port | Connection Method   |
|-------------------------------------|-----------------|:------------:|---------------------|
| [PostgreSQL](postgres.md)           | `postgres:latest` | 5432       | `database_url`      |
| [MySQL](mysql.md)                   | `mysql:latest`    | 3306       | `database_url`      |
| [Redis](redis.md)                   | `redis:latest`    | 6379       | `redis_url`         |
| [MongoDB](mongodb.md)               | `mongo:latest`    | 27017      | `connection_url`    |

## Usage pattern

All modules follow the same fluent API pattern as `DockerContainer`:

1. **Configure** using the module class (e.g., `PostgresContainer.new`), calling fluent `with_*` methods that return `self`.
2. **Start** with `.start`, which returns `self` for method chaining.
3. **Use** convenience methods like `database_url` to get connection strings.

```crystal
# 1. Configure
container = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

# 2. Start
container.start

# 3. Use
url = container.database_url
# => "postgres://admin:secret@localhost:XXXXX/testdb"

# Cleanup
container.stop
container.remove
```

## Image versions

Each module defaults to the `latest` tag. Pass an image string to the initializer to pin a specific version:

```crystal
container = Testcontainers::PostgresContainer.new("postgres:16")
  .with_database("testdb")
container.start
```

!!! tip

    Always pin image versions in CI to avoid flaky tests caused by image updates.

## Creating a new module

To add a new module, follow the existing pattern in `src/testcontainers/containers/`:

1. Create a new class inheriting from `DockerContainer` with sensible defaults (image, port, environment variables, wait strategy).
2. Add fluent builder methods (e.g., `with_database`, `with_username`) that return `self`.
3. Expose a convenience method like `database_url` or `connection_url`.
4. Override `start` to set up exposed ports and environment variables, then call `super`.

```crystal
module Testcontainers
  class MyServiceContainer < DockerContainer
    DEFAULT_PORT  = 1234
    DEFAULT_IMAGE = "myservice:latest"

    def initialize(image : String = DEFAULT_IMAGE)
      super(image)
      with_wait_for_tcp_port(DEFAULT_PORT) unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(port)
      configure_env
      super
    end

    def port : Int32
      DEFAULT_PORT
    end

    def with_some_setting(value : String) : self
      @some_setting = value
      self
    end

    def connection_url : String
      "myservice://#{host}:#{mapped_port(port)}"
    end

    private def configure_env : Nil
      with_env("MY_SETTING", @some_setting || "default")
    end
  end
end
```

See [AGENTS.md](https://github.com/testcontainers/testcontainers-crystal/blob/main/AGENTS.md) for the full contribution guidelines for adding modules.
