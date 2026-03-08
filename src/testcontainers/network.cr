require "docr"
require "uuid"

module Testcontainers
  # Network provides a wrapper around Docker networks for multi-container test scenarios.
  #
  # Example:
  # ```
  # network = Testcontainers::Network.new(name: "my-test-network")
  # network.create!
  #
  # container.with_network_mode(network.name).start
  #
  # network.remove
  # ```
  class Network
    Log = Testcontainers::Log.for("network")

    DEFAULT_DRIVER = "bridge"

    getter name : String
    getter driver : String
    getter network_id : String?
    getter labels : Hash(String, String)

    def initialize(
      @name : String = Network.generate_name,
      @driver : String = DEFAULT_DRIVER,
    )
      @network_id = nil
      @labels = DockerClient.default_labels
    end

    # Provides a concise string representation for debugging.
    def inspect(io : IO) : Nil
      io << "#<" << self.class << " name=" << @name
      if id = @network_id
        io << " id=" << id
      end
      io << ">"
    end

    # Creates the Docker network (idempotent).
    def create! : self
      return self if @network_id

      config = Docr::Types::NetworkConfig.new(
        name: @name,
        driver: @driver,
        check_duplicate: true,
        labels: @labels,
      )

      response = DockerClient.api.networks.create(config)
      @network_id = response.id
      Log.info { "Created network: #{@name} (#{@network_id})" }
      self
    rescue ex : Docr::Errors::DockerAPIError
      if ex.message.try(&.includes?("already exists"))
        raise AlreadyExistsError.new("Network '#{@name}' already exists: #{ex.message}")
      end
      raise Error.new("Failed to create network: #{ex.message}")
    end

    # Returns whether the network has been created.
    def created? : Bool
      !@network_id.nil?
    end

    # Returns network information from Docker.
    def info : Docr::Types::Network
      id = @network_id || raise Error.new("Network has not been created")
      DockerClient.api.networks.inspect(id)
    end

    # Removes/deletes the network.
    def remove : self
      if id = @network_id
        Log.info { "Removing network: #{@name}" }
        DockerClient.api.networks.delete(id)
        @network_id = nil
      end
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise Error.new("Failed to remove network: #{ex.message}")
    end

    # Alias for remove.
    def close : self
      remove
    end

    # Alias for remove.
    def destroy : self
      remove
    end

    # Creates the network, yields it, then removes it.
    def self.create(name : String? = nil, driver : String = DEFAULT_DRIVER, &)
      network = new(name: name || generate_name, driver: driver)
      network.create!
      begin
        yield network
      ensure
        network.remove
      end
    end

    # Generates a unique network name.
    def self.generate_name : String
      "testcontainers-network-#{UUID.random}"
    end
  end
end
