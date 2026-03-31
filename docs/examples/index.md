# Examples

This page demonstrates common usage patterns for Testcontainers for Crystal, from basic container management through to multi-container setups.

## Basic HTTP container

Start an NGINX container, wait for it to be ready, and make an HTTP request:

```crystal
require "testcontainers"
require "http/client"

container = Testcontainers::DockerContainer.new("nginx:1.26-alpine")
  .with_exposed_port(80)
  .with_wait_for_http(port: 80)
  .start

begin
  host = container.host
  port = container.mapped_port(80)

  response = HTTP::Client.get("http://#{host}:#{port}")
  puts "Status: #{response.status_code}" # 200
ensure
  container.stop
  container.remove
end
```

## Database module

Use the pre-configured [PostgreSQL module](../modules/postgres.md) for zero-config database testing:

```crystal
require "testcontainers"

container = Testcontainers::PostgresContainer.new
  .with_database("myapp_test")
  .with_username("admin")
  .with_password("secret")
  .start

begin
  puts container.database_url
  # "postgres://admin:secret@localhost:55432/myapp_test"
ensure
  container.stop
  container.remove
end
```

Or use the block form for automatic cleanup:

```crystal
Testcontainers::PostgresContainer.new
  .with_database("myapp_test")
  .with_username("admin")
  .with_password("secret")
  .use do |container|
    puts container.database_url
  end
```

## Combined wait strategies

Wait for multiple conditions before considering a container ready:

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)
  .with_wait_for_tcp_port(5432)
  .with_wait_for_logs(/database system is ready to accept connections/)
  .start

begin
  # Container is guaranteed to have port 5432 listening
  # AND the log message present
ensure
  container.stop
  container.remove
end
```

## Multi-container setup

Start multiple service containers for integration testing:

```crystal
require "testcontainers"

pg = Testcontainers::PostgresContainer.new
  .with_database("mydb")
  .with_username("admin")
  .with_password("secret")
  .start

redis = Testcontainers::RedisContainer.new.start

begin
  puts "PostgreSQL: #{pg.database_url}"
  puts "Redis: #{redis.redis_url}"
ensure
  pg.stop
  pg.remove
  redis.stop
  redis.remove
end
```

## Parallel container startup

Start multiple containers concurrently using Crystal fibers:

```crystal
require "testcontainers"

pg_chan = Channel(Testcontainers::PostgresContainer).new
redis_chan = Channel(Testcontainers::RedisContainer).new

spawn do
  container = Testcontainers::PostgresContainer.new
    .with_database("testdb")
    .with_username("admin")
    .with_password("secret")
    .start
  pg_chan.send(container)
end

spawn do
  container = Testcontainers::RedisContainer.new.start
  redis_chan.send(container)
end

pg = pg_chan.receive
redis = redis_chan.receive

begin
  puts "PostgreSQL: #{pg.database_url}"
  puts "Redis: #{redis.redis_url}"
ensure
  pg.stop
  pg.remove
  redis.stop
  redis.remove
end
```

## Executing commands in a container

Run commands inside a running container:

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("alpine:latest")
  .with_command(["sleep", "30"])
  .start

begin
  result = container.exec(["echo", "Hello from Alpine"])
  puts result.output # "Hello from Alpine"
ensure
  container.stop
  container.remove
end
```

## Reading container logs

Access stdout/stderr from a running container:

```crystal
require "testcontainers"

container = Testcontainers::DockerContainer.new("alpine:latest")
  .with_command(["sh", "-c", "echo 'Application started' && sleep 30"])
  .start

begin
  sleep 2
  logs = container.logs
  puts logs # "Application started\n"
ensure
  container.stop
  container.remove
end
```

## Crystal spec integration

See the [Crystal Spec Integration](../test_frameworks/crystal_spec.md) page for complete testing patterns, including `before_each`/`after_each`, shared containers, and parallel test support.

```crystal
require "spec"
require "testcontainers"

describe "Integration Tests" do
  container = Testcontainers::PostgresContainer.new
    .with_database("testdb")
    .with_username("admin")
    .with_password("secret")

  before_each do
    container.start
  end

  after_each do
    container.stop
    container.remove
  end

  it "connects to database" do
    url = container.database_url
    url.should contain("testdb")
  end
end
```
}
```
