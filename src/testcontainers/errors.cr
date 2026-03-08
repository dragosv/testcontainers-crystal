module Testcontainers
  # Base error class for all Testcontainers errors
  class TestcontainersError < Exception; end

  # Raised when a connection to the Docker daemon fails
  class ConnectionError < TestcontainersError; end

  # Raised when an image is not found
  class NotFoundError < TestcontainersError; end

  class DockerContainer
    # Raised when a container has not been started but an operation requires it
    class NotStartedError < TestcontainersError
      def initialize(message = "Container has not been started")
        super(message)
      end
    end

    # Raised when a container fails to launch
    class LaunchError < TestcontainersError; end

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
  end

  class Network
    # Raised when a network operation fails
    class Error < TestcontainersError; end

    # Raised when a network is not found
    class NotFoundError < Error; end

    # Raised when a network already exists
    class AlreadyExistsError < Error; end
  end

  # Backward-compatible aliases for the old flat error names
  ContainerNotStartedError     = DockerContainer::NotStartedError
  ContainerLaunchError         = DockerContainer::LaunchError
  PortNotMappedError           = DockerContainer::PortNotMappedError
  HealthcheckNotSupportedError = DockerContainer::HealthcheckNotSupportedError
  TimeoutError                 = DockerContainer::TimeoutError
  NetworkError                 = Network::Error
  NetworkNotFoundError         = Network::NotFoundError
  NetworkAlreadyExistsError    = Network::AlreadyExistsError
end
