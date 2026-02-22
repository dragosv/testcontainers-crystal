require "docr"
require "socket"
require "http/client"
require "uri"

module Testcontainers
  # DockerContainer is the main class for managing Docker containers in tests.
  # It provides a fluent API to configure, start, stop, and interact with containers.
  #
  # Example:
  # ```
  # container = Testcontainers::DockerContainer.new("redis:latest")
  #   .with_exposed_port(6379)
  #   .with_env("REDIS_PASSWORD", "secret")
  #
  # container.start
  # host = container.host
  # port = container.mapped_port(6379)
  #
  # # ... run tests ...
  #
  # container.stop
  # container.remove
  # ```
  class DockerContainer
    # Container configuration properties
    property name : String?
    property image : String
    property command : Array(String)?
    property entrypoint : Array(String)?
    property exposed_ports : Hash(String, Hash(String, String))
    property port_bindings : Hash(String, Array(Docr::Types::PortBinding))
    property volumes : Hash(String, Hash(String, String))
    property filesystem_binds : Array(String)
    property env : Array(String)
    property labels : Hash(String, String)
    property working_dir : String?
    property healthcheck : Docr::Types::HealthConfig?

    # Wait strategy: a Proc that receives the container and waits for readiness
    property wait_for : Proc(DockerContainer, Nil)?

    # The container ID once created
    getter container_id : String?

    # The creation timestamp
    getter created_at : String?

    @_api : Docr::API?
    @wait_for_user_defined : Bool = false

    # Initializes a new DockerContainer.
    #
    # - image: The Docker image to use (e.g. "redis:latest")
    def initialize(@image : String)
      @name = nil
      @command = nil
      @entrypoint = nil
      @exposed_ports = Hash(String, Hash(String, String)).new
      @port_bindings = Hash(String, Array(Docr::Types::PortBinding)).new
      @volumes = Hash(String, Hash(String, String)).new
      @filesystem_binds = Array(String).new
      @env = Array(String).new
      @labels = Hash(String, String).new
      @working_dir = nil
      @healthcheck = nil
      @wait_for = nil
      @wait_for_user_defined = false
      @container_id = nil
      @created_at = nil
      @_api = nil

      add_labels(default_labels)
    end

    # Returns the Docr API client
    private def api : Docr::API
      @_api ||= DockerClient.api
    end

    # ---- Fluent configuration methods (with_*) ----

    # Sets the container name.
    def with_name(name : String) : self
      @name = name
      self
    end

    # Sets the command to run in the container.
    def with_command(*parts : String) : self
      @command = parts.to_a
      self
    end

    # Sets the command to run in the container from an array.
    def with_command(cmd : Array(String)) : self
      @command = cmd
      self
    end

    # Sets the entrypoint for the container.
    def with_entrypoint(*parts : String) : self
      @entrypoint = parts.to_a
      self
    end

    # Sets the entrypoint for the container from an array.
    def with_entrypoint(entrypoint : Array(String)) : self
      @entrypoint = entrypoint
      self
    end

    # Adds a single exposed port to the container.
    # The port will be mapped to a random host port.
    def with_exposed_port(port : Int32 | String) : self
      add_exposed_port(port)
      self
    end

    # Adds multiple exposed ports to the container.
    def with_exposed_ports(*ports : Int32 | String) : self
      ports.each { |port| add_exposed_port(port) }
      self
    end

    # Adds multiple exposed ports from an array.
    def with_exposed_ports(ports : Array(Int32 | String)) : self
      ports.each { |port| add_exposed_port(port) }
      self
    end

    # Adds a fixed port mapping (container_port -> host_port).
    def with_fixed_exposed_port(container_port : Int32 | String, host_port : Int32) : self
      add_fixed_exposed_port(container_port, host_port)
      self
    end

    # Sets environment variables from a Hash.
    def with_env(env : Hash(String, String)) : self
      env.each { |key, value| add_env("#{key}=#{value}") }
      self
    end

    # Sets a single environment variable.
    def with_env(key : String, value : String) : self
      add_env("#{key}=#{value}")
      self
    end

    # Sets environment variables from an array of "KEY=VALUE" strings.
    def with_env(env : Array(String)) : self
      env.each { |e| add_env(e) }
      self
    end

    # Sets the working directory inside the container.
    def with_working_dir(working_dir : String) : self
      @working_dir = working_dir
      self
    end

    # Adds volumes.
    def with_volumes(volumes : Hash(String, Hash(String, String))) : self
      @volumes.merge!(volumes)
      self
    end

    # Adds a single volume.
    def with_volume(volume : String) : self
      @volumes[volume] = Hash(String, String).new
      self
    end

    # Adds a filesystem bind mount.
    def with_filesystem_bind(host_path : String, container_path : String, mode : String = "rw") : self
      @filesystem_binds << "#{host_path}:#{container_path}:#{mode}"
      @volumes[container_path] = Hash(String, String).new
      self
    end

    # Adds multiple filesystem binds.
    def with_filesystem_binds(binds : Array(String)) : self
      binds.each do |bind|
        parts = bind.split(":")
        host_path = parts[0]
        container_path = parts[1]? || parts[0]
        mode = parts[2]? || "rw"
        with_filesystem_bind(host_path, container_path, mode)
      end
      self
    end

    # Adds labels to the container.
    def with_labels(labels : Hash(String, String)) : self
      add_labels(labels)
      self
    end

    # Adds a single label.
    def with_label(key : String, value : String) : self
      @labels[key] = value
      self
    end

    # Configures a healthcheck for the container.
    #
    # Options:
    # - test: Command to run (string or array)
    # - interval: Seconds between checks (default: 30)
    # - timeout: Seconds before check is considered hung (default: 30)
    # - retries: Number of retries before unhealthy (default: 3)
    # - shell: Whether to use CMD-SHELL (default: false)
    def with_healthcheck(
      test : String | Array(String),
      interval : Float64 = 30.0,
      timeout : Float64 = 30.0,
      retries : Int32 = 3,
      shell : Bool = false,
      start_period : Float64 = 0.0
    ) : self
      test_arr = test.is_a?(String) ? test.split(" ") : test
      test_cmd = shell ? ["CMD-SHELL"] + test_arr : ["CMD"] + test_arr

      @healthcheck = Docr::Types::HealthConfig.new(
        test: test_cmd,
        interval: (interval * 1_000_000_000).to_i64,
        timeout: (timeout * 1_000_000_000).to_i64,
        retries: retries.to_i64,
        start_period: (start_period * 1_000_000_000).to_i64,
      )
      self
    end

    # Sets a custom wait strategy block.
    # The block receives the container instance and should block until the container is ready.
    def with_wait_for(&block : DockerContainer -> Nil) : self
      @wait_for = block
      @wait_for_user_defined = true
      self
    end

    # Sets the wait strategy to wait for a specific log message.
    def with_wait_for_logs(matcher : Regex, timeout : Int32 = 60, interval : Float64 = 0.5) : self
      @wait_for = ->(container : DockerContainer) {
        container.wait_for_logs(matcher, timeout: timeout, interval: interval)
        nil
      }
      @wait_for_user_defined = true
      self
    end

    # Sets the wait strategy to wait for a TCP port.
    def with_wait_for_tcp_port(port : Int32, timeout : Int32 = 60, interval : Float64 = 0.5) : self
      @wait_for = ->(container : DockerContainer) {
        container.wait_for_tcp_port(port, timeout: timeout, interval: interval)
        nil
      }
      @wait_for_user_defined = true
      self
    end

    # Sets the wait strategy to wait for the healthcheck.
    def with_wait_for_healthcheck(timeout : Int32 = 60, interval : Float64 = 0.5) : self
      @wait_for = ->(container : DockerContainer) {
        container.wait_for_healthcheck(timeout: timeout, interval: interval)
        nil
      }
      @wait_for_user_defined = true
      self
    end

    # Sets the wait strategy to wait for an HTTP endpoint.
    def with_wait_for_http(
      path : String = "/",
      container_port : Int32 = 80,
      timeout : Int32 = 60,
      interval : Float64 = 0.5,
      status : Int32 = 200,
      https : Bool = false
    ) : self
      @wait_for = ->(container : DockerContainer) {
        container.wait_for_http(
          path: path,
          container_port: container_port,
          timeout: timeout,
          interval: interval,
          status: status,
          https: https,
        )
        nil
      }
      @wait_for_user_defined = true
      self
    end

    # Returns whether the wait strategy was explicitly set by the user.
    def wait_for_user_defined? : Bool
      @wait_for_user_defined
    end

    # ---- Container lifecycle methods ----

    # Starts the container.
    #
    # This will:
    # 1. Pull the image if not present
    # 2. Create the container
    # 3. Start the container
    # 4. Execute the wait strategy (if any)
    #
    # Returns self for method chaining.
    def start : self
      # Set default wait strategy if not user-defined
      unless @wait_for_user_defined
        if !@exposed_ports.empty?
          port = @exposed_ports.keys.first.split("/").first.to_i
          @wait_for = ->(container : DockerContainer) {
            container.wait_for_tcp_port(port)
            nil
          }
        end
      end

      # Pull image if not present
      begin
        api.images.inspect(@image)
      rescue Docr::Errors::DockerAPIError
        Testcontainers.logger.info { "Pulling image: #{@image}" }
        image_parts = @image.split(":")
        image_name = image_parts[0]
        image_tag = image_parts[1]? || "latest"
        api.images.create(image_name, tag: image_tag)
      end

      # Create container configuration
      config = build_container_config

      # Create the container
      container_name = @name || "testcontainers-#{UUID.random}"
      Testcontainers.logger.info { "Creating container from image: #{@image}" }

      response = api.containers.create(container_name, config)
      @container_id = response.id

      # Start the container
      Testcontainers.logger.info { "Starting container: #{@container_id}" }
      api.containers.start(@container_id.not_nil!)

      # Fetch container details
      inspect_data = api.containers.inspect(@container_id.not_nil!)
      @name = inspect_data.name.lstrip('/')
      @created_at = inspect_data.created

      # Execute wait strategy
      if wait_proc = @wait_for
        Testcontainers.logger.info { "Waiting for container to be ready..." }
        wait_proc.call(self)
        Testcontainers.logger.info { "Container is ready" }
      end

      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Starts the container, yields it to a block, then stops and removes it.
    def use(&) : self
      start
      yield self
      self
    ensure
      stop rescue nil
      remove rescue nil
    end

    # Stops the container.
    def stop(force : Bool = false) : self
      raise ContainerNotStartedError.new unless @container_id
      Testcontainers.logger.info { "Stopping container: #{@container_id}" }
      if force
        api.containers.kill(@container_id.not_nil!)
      else
        api.containers.stop(@container_id.not_nil!)
      end
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Stops the container forcefully.
    def stop! : self
      stop(force: true)
    end

    # Kills the container with the specified signal.
    def kill(signal : String = "SIGKILL") : self
      raise ContainerNotStartedError.new unless @container_id
      api.containers.kill(@container_id.not_nil!, signal)
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Removes/deletes the container.
    def remove(force : Bool = false, volumes : Bool = false) : self
      if id = @container_id
        Testcontainers.logger.info { "Removing container: #{id}" }
        api.containers.delete(id, volumes: volumes, force: force)
        @container_id = nil
      end
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Alias for remove.
    def delete(force : Bool = false, volumes : Bool = false) : self
      remove(force: force, volumes: volumes)
    end

    # Restarts the container.
    def restart : self
      raise ContainerNotStartedError.new unless @container_id
      api.containers.restart(@container_id.not_nil!)
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Pauses the container.
    def pause : self
      raise ContainerNotStartedError.new unless @container_id
      api.containers.pause(@container_id.not_nil!)
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Unpauses the container.
    def unpause : self
      raise ContainerNotStartedError.new unless @container_id
      api.containers.unpause(@container_id.not_nil!)
      self
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # ---- Container status methods ----

    # Returns the container's status string.
    # Possible values: "created", "running", "paused", "restarting", "removing", "exited", "dead"
    def status : String
      raise ContainerNotStartedError.new unless @container_id
      inspect_data = api.containers.inspect(@container_id.not_nil!)
      inspect_data.state.try(&.status) || "unknown"
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Returns whether the container is running.
    def running? : Bool
      status == "running"
    rescue ContainerNotStartedError
      false
    end

    # Returns whether the container is stopped/exited.
    def exited? : Bool
      status == "exited"
    end

    # Returns whether the container is paused.
    def paused? : Bool
      status == "paused"
    end

    # Returns whether the container is dead.
    def dead? : Bool
      status == "dead"
    end

    # Returns whether the container is restarting.
    def restarting? : Bool
      status == "restarting"
    end

    # Returns whether the container is healthy.
    def healthy? : Bool
      raise ContainerNotStartedError.new unless @container_id
      raise HealthcheckNotSupportedError.new unless supports_healthcheck?
      inspect_data = api.containers.inspect(@container_id.not_nil!)
      inspect_data.state.try(&.health).try(&.status) == "healthy"
    rescue ContainerNotStartedError
      false
    end

    # Returns whether the container supports healthchecks.
    def supports_healthcheck? : Bool
      raise ContainerNotStartedError.new unless @container_id
      inspect_data = api.containers.inspect(@container_id.not_nil!)
      !inspect_data.config.healthcheck.nil?
    end

    # Returns whether the container exists.
    def exists? : Bool
      return false unless @container_id
      api.containers.inspect(@container_id.not_nil!)
      true
    rescue Docr::Errors::DockerAPIError
      false
    end

    # ---- Container information methods ----

    # Returns the container's full inspect data.
    def info : Docr::Types::ContainerInspectResponse
      raise ContainerNotStartedError.new unless @container_id
      api.containers.inspect(@container_id.not_nil!)
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Returns the container's host address.
    def host : String
      raise ContainerNotStartedError.new unless @container_id
      DockerClient.host
    end

    # Returns the mapped host port for the given container port.
    def mapped_port(port : Int32 | String) : Int32
      raise ContainerNotStartedError.new unless @container_id
      normalized = normalize_port(port)

      inspect_data = api.containers.inspect(@container_id.not_nil!)
      ports = inspect_data.network_settings.ports

      if bindings = ports[normalized]?
        if binding = bindings.try(&.first?)
          if host_port = binding.host_port
            return host_port.to_i
          end
        end
      end

      raise PortNotMappedError.new("Port #{port} is not mapped")
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Returns the first mapped port.
    def first_mapped_port : Int32
      raise ContainerNotStartedError.new unless @container_id
      port = @exposed_ports.keys.first?.try(&.split("/").first.to_i)
      raise PortNotMappedError.new("No exposed ports") unless port
      mapped_port(port)
    end

    # Returns the container's logs.
    def logs(stdout : Bool = true, stderr : Bool = true) : String
      raise ContainerNotStartedError.new unless @container_id
      output = String::Builder.new

      if stdout
        io = api.containers.logs(@container_id.not_nil!, stdout: true, stderr: false)
        output << strip_docker_log_headers(io.gets_to_end)
      end

      if stderr
        io = api.containers.logs(@container_id.not_nil!, stdout: false, stderr: true)
        output << strip_docker_log_headers(io.gets_to_end)
      end

      output.to_s
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # Returns an environment variable value from the container config.
    def get_env(key : String) : String?
      entry = @env.find { |e| e.starts_with?("#{key}=") }
      entry.try(&.split("=", 2).last?)
    end

    # Executes a command in the container.
    #
    # Returns the output from the command.
    def exec(cmd : Array(String)) : String
      raise ContainerNotStartedError.new unless @container_id

      exec_config = Docr::Types::ExecConfig.new(
        attach_stdout: true,
        attach_stderr: true,
        cmd: cmd,
      )

      exec_response = api.exec.container(@container_id.not_nil!, exec_config)
      exec_id = exec_response.id

      start_config = Docr::Types::ExecStartConfig.new(
        detach: false,
        tty: false,
      )

      io = api.exec.start(exec_id, start_config)
      strip_docker_log_headers(io.gets_to_end)
    rescue ex : Docr::Errors::DockerAPIError
      raise ConnectionError.new("Docker API error: #{ex.message}")
    end

    # ---- Wait strategies ----

    # Waits for the container's logs to match the given regex.
    def wait_for_logs(matcher : Regex, timeout : Int32 = 60, interval : Float64 = 0.5) : Bool
      raise ContainerNotStartedError.new unless @container_id

      deadline = Time.instant + timeout.seconds
      loop do
        output = logs(stdout: true, stderr: true)
        return true if output.matches?(matcher)
        raise TimeoutError.new("Timed out waiting for logs to match #{matcher.source}") if Time.instant >= deadline
        sleep interval.seconds
      end
    end

    # Waits for a TCP port to be open.
    def wait_for_tcp_port(port : Int32, timeout : Int32 = 60, interval : Float64 = 0.5) : Bool
      raise ContainerNotStartedError.new unless @container_id

      host_addr = host
      host_port = mapped_port(port)

      deadline = Time.instant + timeout.seconds
      loop do
        begin
          socket = TCPSocket.new(host_addr, host_port, connect_timeout: interval)
          socket.close
          return true
        rescue IO::Error | Socket::ConnectError
          # Port not ready yet
        end
        raise TimeoutError.new("Timed out waiting for port #{port} to open") if Time.instant >= deadline
        sleep interval.seconds
      end
    end

    # Waits for the container to be healthy.
    def wait_for_healthcheck(timeout : Int32 = 60, interval : Float64 = 0.5) : Bool
      raise ContainerNotStartedError.new unless @container_id
      raise HealthcheckNotSupportedError.new unless supports_healthcheck?

      deadline = Time.instant + timeout.seconds
      loop do
        return true if healthy?
        raise TimeoutError.new("Timed out waiting for healthcheck") if Time.instant >= deadline
        sleep interval.seconds
      end
    end

    # Waits for an HTTP endpoint to respond with the expected status code.
    def wait_for_http(
      path : String = "/",
      container_port : Int32 = 80,
      timeout : Int32 = 60,
      interval : Float64 = 0.5,
      status : Int32 = 200,
      https : Bool = false
    ) : Bool
      raise ContainerNotStartedError.new unless @container_id

      host_addr = host
      host_port = mapped_port(container_port)
      scheme = https ? "https" : "http"
      url = "#{scheme}://#{host_addr}:#{host_port}#{path}"

      deadline = Time.instant + timeout.seconds
      loop do
        begin
          response = HTTP::Client.get(url)
          return true if response.status_code == status
        rescue IO::Error | Socket::ConnectError
          # Not ready yet
        end
        raise TimeoutError.new("Timed out waiting for HTTP #{status} on #{path}") if Time.instant >= deadline
        sleep interval.seconds
      end
    end

    # ---- Private helpers ----

    private def add_exposed_port(port : Int32 | String)
      normalized = normalize_port(port)
      @exposed_ports[normalized] = Hash(String, String).new
      @port_bindings[normalized] ||= [Docr::Types::PortBinding.new(host_ip: "", host_port: "")]
    end

    private def add_fixed_exposed_port(container_port : Int32 | String, host_port : Int32)
      normalized = normalize_port(container_port)
      @exposed_ports[normalized] = Hash(String, String).new
      @port_bindings[normalized] = [Docr::Types::PortBinding.new(host_ip: "", host_port: host_port.to_s)]
    end

    private def add_env(env_str : String)
      @env << env_str
    end

    private def add_labels(labels : Hash(String, String))
      @labels.merge!(labels)
    end

    private def default_labels : Hash(String, String)
      {
        "org.testcontainers.lang"    => "crystal",
        "org.testcontainers.version" => Testcontainers::VERSION,
      }
    end

    private def normalize_port(port : Int32 | String) : String
      port_str = port.to_s
      port_str = "#{port_str}/tcp" unless port_str.includes?("/")
      port_str
    end

    private def build_container_config : Docr::Types::CreateContainerConfig
      host_config = Docr::Types::HostConfig.new(
        port_bindings: @port_bindings.empty? ? nil : @port_bindings,
        binds: @filesystem_binds.empty? ? nil : @filesystem_binds,
      )

      exposed = @exposed_ports.empty? ? nil : @exposed_ports

      Docr::Types::CreateContainerConfig.new(
        image: @image,
        cmd: @command,
        entrypoint: @entrypoint,
        env: @env.empty? ? nil : @env,
        exposed_ports: exposed,
        labels: @labels.empty? ? nil : @labels,
        working_dir: @working_dir,
        healthcheck: @healthcheck,
        host_config: host_config,
      )
    end

    # Strips Docker multiplexed stream headers from log output.
    # Docker daemon prepends 8-byte headers to each frame in multiplexed mode.
    private def strip_docker_log_headers(raw : String) : String
      return raw if raw.empty?

      result = String::Builder.new
      io = IO::Memory.new(raw)

      loop do
        # Read 8-byte header: [stream_type(1), 0, 0, 0, size(4 big-endian)]
        header = Bytes.new(8)
        bytes_read = io.read(header)
        break if bytes_read < 8

        size = (header[4].to_u32 << 24) | (header[5].to_u32 << 16) | (header[6].to_u32 << 8) | header[7].to_u32
        break if size == 0

        payload = Bytes.new(size)
        io.read_fully(payload)
        result << String.new(payload)
      rescue IO::EOFError
        break
      end

      output = result.to_s
      # If stripping didn't produce output, the logs might not be multiplexed
      output.empty? ? raw : output
    end
  end

  # Alias for DockerContainer, following testcontainers convention
  alias GenericContainer = DockerContainer
end
