module Testcontainers
  # Base error class for all Testcontainers errors
  class TestcontainersError < Exception; end

  # Raised when a connection to the Docker daemon fails
  class ConnectionError < TestcontainersError; end

  # Raised when a container has not been started but an operation requires it
  class ContainerNotStartedError < TestcontainersError
    def initialize(message = "Container has not been started")
      super(message)
    end
  end

  # Raised when a container fails to launch
  class ContainerLaunchError < TestcontainersError; end

  # Raised when an image is not found
  class NotFoundError < TestcontainersError; end

  # Raised when a port is not mapped
  class PortNotMappedError < TestcontainersError
    def initialize(message = "Port is not mapped")
      super(message)
    end
  end

  # Raised when the container does not support healthchecks
  class HealthcheckNotSupportedError < TestcontainersError
    def initialize(message = "Container does not support healthchecks")
      super(message)
    end
  end

  # Raised when a timeout occurs (e.g., waiting for logs, ports, etc.)
  class TimeoutError < TestcontainersError; end

  # Raised when a network operation fails
  class NetworkError < TestcontainersError; end

  # Raised when a network is not found
  class NetworkNotFoundError < NetworkError; end

  # Raised when a network already exists
  class NetworkAlreadyExistsError < NetworkError; end
end
