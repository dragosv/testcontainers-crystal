# Garbage Collector

Typically, an integration test creates one or more containers. This can mean a lot of containers running by the time everything is done. We need to have a way to clean up after ourselves to keep our machines running smoothly.

Containers can be unused because:

1. The test is over and the container is not needed anymore.
2. The test failed, and we do not need that container anymore because the next build will create new ones.

## Cleanup patterns

### Using `begin/ensure`

The most common pattern for cleaning up containers is `begin/ensure`:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)

begin
  container.start

  # Test logic...
ensure
  container.stop rescue nil
  container.remove rescue nil
end
```

!!! tip

    Use `rescue nil` when stopping containers in cleanup code to avoid masking the original test failure with a cleanup error.

### Using the `use` block

The `use` method on `DockerContainer` automatically stops and removes the container:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_env("POSTGRES_PASSWORD", "password")
  .with_exposed_port(5432)

container.use do |c|
  # Test logic using c...
end
# Container is automatically stopped and removed
```

### Using spec lifecycle hooks

Use `before_each` and `after_each` in Crystal spec to manage container lifecycle:

```crystal
describe "Database" do
  container = Testcontainers::DockerContainer.new("postgres:16")
    .with_env("POSTGRES_PASSWORD", "password")
    .with_exposed_port(5432)
    .with_wait_for_tcp_port(5432)

  before_each do
    container.start
  end

  after_each do
    container.stop rescue nil
    container.remove rescue nil
  end

  it "runs a query" do
    # container is available and started
  end
end
```

### Using labels for CI cleanup

You can label containers and clean them up in CI scripts as a safety net:

```crystal
container = Testcontainers::DockerContainer.new("postgres:16")
  .with_label("testcontainers", "true")
  .with_label("testcontainers.session", UUID.random.to_s)
```

Then in your CI pipeline:

```bash
# Clean up any leftover test containers
docker rm -f $(docker ps -aq --filter "label=testcontainers=true") 2>/dev/null || true
```

## Resource Reaper (Ryuk)

!!! note "Not yet implemented"

    Automatic resource reaping (Ryuk) is not yet available in Testcontainers for Crystal. This feature is planned for a future release.

In other Testcontainers implementations, a "resource reaper" called [Ryuk](https://github.com/testcontainers/moby-ryuk) runs as a sidecar container that automatically cleans up containers, networks, and volumes created during tests — even if the test process crashes or is killed.

When available, you will see an additional container called `ryuk` alongside all the containers that were specified in your test. It relies on container labels to determine which resources were created by the package to determine the entities that are safe to remove.

Until the resource reaper is implemented, ensure you clean up resources using one of the manual patterns described above.

!!! tip

    In CI environments, consider adding a post-build step to clean up any Docker containers with the `testcontainers` label as a safety net.
