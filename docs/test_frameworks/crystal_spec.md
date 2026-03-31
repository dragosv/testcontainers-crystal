# Crystal Spec Integration

Testcontainers for Crystal integrates with Crystal's built-in [spec](https://crystal-lang.org/reference/guides/testing.html) framework. This page covers recommended patterns for managing container lifecycles in your tests.

## Per-test container with `begin/ensure`

The simplest pattern — start a container at the beginning of a test and clean up with `ensure`:

```crystal
require "testcontainers"
require "spec"

describe "Redis" do
  it "connects to Redis" do
    container = Testcontainers::RedisContainer.new
    begin
      container.start

      url = container.redis_url
      url.should start_with("redis://")
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

This is ideal when a test needs its own isolated container.

## Per-test container with `before_each` / `after_each`

Use `before_each` and `after_each` when every test in a describe block needs the same container type:

```crystal
require "testcontainers"
require "spec"

describe "Database" do
  container = Testcontainers::PostgresContainer.new
    .with_database("testdb")
    .with_username("admin")
    .with_password("secret")

  before_each do
    container.start
  end

  after_each do
    container.stop rescue nil
    container.remove rescue nil
  end

  it "inserts data" do
    url = container.database_url
    url.should start_with("postgres://")
  end

  it "selects data" do
    url = container.database_url
    url.should contain("testdb")
  end
end
```

Each test method gets a fresh container, ensuring complete isolation.

## Shared container across a describe block

To avoid the overhead of starting a new container for every test, share one container across the block:

```crystal
require "testcontainers"
require "spec"

describe "Shared container" do
  container = Testcontainers::PostgresContainer.new
    .with_database("testdb")
    .with_username("admin")
    .with_password("secret")

  before_all do
    container.start
  end

  after_all do
    container.stop rescue nil
    container.remove rescue nil
  end

  it "inserts data" do
    url = container.database_url
    # Use shared container...
  end

  it "selects data" do
    url = container.database_url
    # Use shared container...
  end
end
```

!!! warning

    When sharing containers, ensure tests don't leave state that interferes with other tests. Consider resetting data between tests or using separate databases.

## Generic container test

Use `DockerContainer` directly for images that don't have a pre-configured [module](../modules/index.md):

```crystal
require "testcontainers"
require "spec"

describe "Custom container" do
  it "runs httpbin" do
    container = Testcontainers::DockerContainer.new("httpbin/httpbin:latest")
      .with_exposed_port(80)
      .with_wait_for_http(path: "/uuid", container_port: 80)

    begin
      container.start

      host = container.host
      port = container.mapped_port(80)

      response = HTTP::Client.get("http://#{host}:#{port}/uuid")
      response.status_code.should eq(200)
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

## Parallel container startup

Start multiple containers concurrently using fibers:

```crystal
require "testcontainers"
require "spec"

describe "Multiple services" do
  it "starts postgres and redis" do
    pg = Testcontainers::PostgresContainer.new
      .with_database("testdb")
      .with_username("admin")
      .with_password("secret")

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

    begin
      pg.database_url.should start_with("postgres://")
      redis.redis_url.should start_with("redis://")
    ensure
      pg.stop rescue nil
      pg.remove rescue nil
      redis.stop rescue nil
      redis.remove rescue nil
    end
  end
end
```

## Block-based container lifecycle

Use the `use` method for automatic cleanup:

```crystal
require "testcontainers"
require "spec"

describe "Block lifecycle" do
  it "auto-cleans with use block" do
    container = Testcontainers::DockerContainer.new("redis:7-alpine")
      .with_exposed_port(6379)

    container.use do |c|
      c.running?.should be_true
      port = c.mapped_port(6379)
      port.should be > 0
    end

    container.exists?.should be_false
  end
end
```

## Executing commands

Run commands inside a container and assert on the output:

```crystal
require "testcontainers"
require "spec"

describe "Exec" do
  it "runs commands in container" do
    container = Testcontainers::DockerContainer.new("alpine:latest")
      .with_command("sleep", "30")
      .with_exposed_port(80)

    begin
      container.start

      output = container.exec(["echo", "Hello from Alpine"])
      output.should contain("Hello from Alpine")
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

## Checking container logs

Assert on log output from a container:

```crystal
require "testcontainers"
require "spec"

describe "Logs" do
  it "retrieves container logs" do
    container = Testcontainers::DockerContainer.new("alpine:latest")
      .with_command("sh", "-c", "echo 'Test output' && sleep 30")

    begin
      container.start
      sleep 2.seconds

      logs = container.logs
      logs.should contain("Test output")
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

## Best practices

| Practice | Recommendation |
|----------|---------------|
| **Cleanup** | Always use `begin/ensure` or `after_each` to stop and remove containers |
| **Isolation** | Prefer per-test containers unless startup cost is prohibitive |
| **Timeouts** | Set generous test timeouts — container pulls can be slow |
| **Port binding** | Always use `with_exposed_port` for random host port assignment |
| **Wait strategies** | Always specify a wait strategy to avoid race conditions |
| **Parallel starts** | Use fibers and channels to start independent containers concurrently |

See [Best Practices](../features/best_practices.md) for more recommendations.
