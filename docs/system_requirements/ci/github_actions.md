# GitHub Actions

Testcontainers for Crystal works out of the box on GitHub-hosted Ubuntu runners, which have Docker pre-installed.

## Ubuntu runners

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: crystallang/crystal:latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: shards install

      - name: Build
        run: crystal build src/testcontainers.cr

      - name: Run tests
        run: crystal spec
```

No additional Docker setup is required — the runner already has Docker installed and running.

## macOS runners

macOS runners do **not** ship with Docker. You must install Docker Desktop (or an alternative like Colima) before running tests:

```yaml
name: Tests (macOS)
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install Crystal
        run: brew install crystal

      - name: Install Docker
        run: |
          brew install --cask docker
          open /Applications/Docker.app
          # Wait for Docker to start
          while ! docker system info > /dev/null 2>&1; do sleep 1; done

      - name: Install dependencies
        run: shards install

      - name: Run tests
        run: crystal spec
```

## Caching

Cache the `lib` directory to speed up subsequent builds:

```yaml
- uses: actions/cache@v3
  with:
    path: lib
    key: ${{ runner.os }}-shards-${{ hashFiles('shard.lock') }}
    restore-keys: |
      ${{ runner.os }}-shards-
```

## Tips

- **Timeouts**: Container image pulls and startup can be slow on first run. Set generous job timeouts.
- **Concurrency**: GitHub Actions Ubuntu runners have 2 vCPUs. If running many containers in parallel, consider a larger runner.
- **Docker layer caching**: Use third-party actions like `docker/build-push-action` with caching to speed up image builds if your tests build custom images.
