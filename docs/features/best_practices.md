# Best practices

This page provides guidelines for writing reliable, maintainable tests with Testcontainers for Crystal.

## Use random host ports

Avoid binding fixed host ports. Use `with_exposed_port` to let Docker assign random host ports, preventing port conflicts, especially in CI environments where tests may run in parallel.

```crystal
# ✅ Good
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_exposed_port(5432)

container.start
port = container.mapped_port(5432)
```

```crystal
# ❌ Avoid
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_fixed_exposed_port(5432, 5432)
```

## Pin image versions

Always use a specific image tag. Never rely on `latest`, which can change unexpectedly and break your tests.

```crystal
# ✅ Good
Testcontainers::DockerContainer.new("postgres:16.4")

# ❌ Avoid
Testcontainers::DockerContainer.new("postgres:latest")
```

## Use wait strategies

Configure a wait strategy so your test only proceeds after the service is fully ready. Without one, tests may fail intermittently due to race conditions.

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)
```

See [Wait Strategies](wait/introduction.md) for all available strategies.

## Use pre-configured modules

When a pre-configured module exists (PostgreSQL, MySQL, Redis, MongoDB), prefer it over raw `DockerContainer`. Modules provide sensible defaults, correct wait strategies, and convenience methods like `database_url`.

```crystal
# ✅ Good — uses the pre-configured module
container = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

container.start
url = container.database_url
```

See [Modules](../modules/index.md) for all available modules.

## Clean up containers

Always clean up containers when tests complete. Use `begin/ensure` or spec lifecycle hooks:

```crystal
# Using begin/ensure
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)

begin
  container.start
  # test logic...
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

See [Garbage Collector](garbage_collector.md) for detailed cleanup patterns.

## Use the `use` block for automatic cleanup

The `use` method automatically stops and removes the container when the block finishes:

```crystal
# ✅ Good
container = Testcontainers::DockerContainer.new("redis:7")
  .with_exposed_port(6379)

container.use do |c|
  # test logic...
end
```

## Use network aliases for inter-container communication

When containers need to communicate, use custom networks with the container's name as its network alias:

```crystal
network = Testcontainers::Network.new(name: "test-net")
network.create!

container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)

container.start
```

See [Networking](networking.md) for detailed networking patterns.

## Start containers in parallel

When you need multiple containers, use fibers and channels to start them concurrently:

```crystal
pg = Testcontainers::PostgresContainer.new
  .with_database("testdb")

redis = Testcontainers::RedisContainer.new

ch = Channel(Nil).new(2)

spawn do
  pg.start
  ch.send(nil)
end

spawn do
  redis.start
  ch.send(nil)
end

2.times { ch.receive }
```

## Configure logging for debugging

Use Crystal's `Log` module to diagnose container issues:

```crystal
require "log"

Log.setup(:debug)
```
