# Contributing to Testcontainers Crystal

Thank you for your interest in contributing to Testcontainers Crystal! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/testcontainers-crystal.git
   cd testcontainers-crystal
   ```
3. Install dependencies:
   ```bash
   shards install
   ```
4. Run the tests:
   ```bash
   crystal spec
   ```

## Development Setup

### Prerequisites

- **Crystal** >= 1.10.0
- **Docker** or Docker Desktop running (for integration tests)
- **Git**

### Project Structure

```
src/testcontainers/              # Library source code
  docker_container.cr            # Core container class
  docker_client.cr               # Docker client wrapper
  network.cr                     # Network management
  errors.cr                      # Exception hierarchy
  containers/                    # Pre-configured modules
spec/                            # Test files
  docker_container_spec.cr       # Core container unit tests
  containers_spec.cr             # Preset container unit tests
  network_spec.cr                # Network unit tests
  integration_spec.cr            # Integration tests (Docker required)
```

## Code Style

- **Indentation**: 2 spaces (Crystal standard)
- **Line length**: ~120 characters
- **Naming**: `PascalCase` for types, `snake_case` for methods/variables/files
- **Documentation**: Add `#` doc comments to all public methods and classes
- **Method chaining**: Builder methods should return `self` to enable chaining
- **Error handling**: Use custom exception classes from `errors.cr`; avoid bare `rescue`

### Crystal Idioms

- Prefer `property` / `getter` macros over manual getter/setter methods
- Use `begin/ensure` for resource cleanup
- Use blocks (`yield`) for scoped resource management (see `Network.create`)
- Prefer string interpolation over concatenation
- Use `nil`-safe navigation (`try`) where appropriate

## Making Changes

### Adding a New Container Module

1. Create `src/testcontainers/containers/myservice.cr`
2. Follow the pattern in `postgres.cr`:
   - Set default image, port, and environment variables
   - Add a wait strategy
   - Expose a `connection_url` method
3. Require the new file in `src/testcontainers.cr`
4. Add unit tests in `spec/containers_spec.cr`

### Module Template

```crystal
module Testcontainers
  class MyServiceContainer < DockerContainer
    IMAGE   = "myservice"
    PORT    = 9000

    def initialize(image = "#{IMAGE}:latest")
      super(image)
      with_exposed_port(PORT)
      with_env("MYSERVICE_SETTING", "value")
      with_wait_for(:logs, message: /ready/)
    end

    def connection_url : String
      port = mapped_port(PORT)
      host = self.host
      "myservice://#{host}:#{port}"
    end
  end
end
```

### Adding a Wait Strategy

1. Add a `wait_for_*` method in `src/testcontainers/docker_container.cr`
2. Follow the existing timeout + retry loop pattern
3. Add tests in `spec/docker_container_spec.cr`

## Testing

### Running Tests

```bash
crystal spec                     # Unit tests (no Docker required)
crystal spec -Dintegration       # Integration tests (Docker required)
```

### Test Guidelines

- Write tests for all new features
- Unit tests should not require Docker — mock or test configuration only
- Integration tests should be gated behind `-Dintegration`
- Clean up containers/networks in tests using `ensure` blocks
- Tests should be deterministic and not flaky
- Test both success paths and error cases

## Pull Requests

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```
2. Make your changes with clear, focused commits
3. Ensure all tests pass: `crystal spec`
4. Push and open a pull request

### PR Guidelines

- Keep PRs focused on a single feature or fix
- Include tests for new functionality
- Update documentation if adding public API
- Reference any related issues

## Git Commits

- Use clear and descriptive commit messages
- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

## Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include Crystal version, Docker version, and OS
- Provide a minimal reproduction case for bugs
- Check existing issues before creating a new one

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to reach out:
- Open an issue on GitHub
- Start a discussion in GitHub Discussions

Thank you for contributing!
