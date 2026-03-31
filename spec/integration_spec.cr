require "./spec_helper"

# Integration tests that require a running Docker daemon.
# These tests actually start/stop containers, so they are tagged.
#
# Run with: crystal spec spec/integration_spec.cr
#
# Note: These tests require Docker to be running and accessible
# via /var/run/docker.sock

{% if flag?(:integration) %}
  def send_redis_command(io : IO, parts : Array(String)) : Nil
    io << "*#{parts.size}\r\n"
    parts.each do |part|
      io << "$#{part.bytesize}\r\n#{part}\r\n"
    end
    io.flush
  end

  def read_redis_response(io : IO) : String
    prefix = io.read_char || raise "Missing Redis response"

    case prefix
    when '+', '-', ':'
      line = io.gets || raise "Missing Redis response line"
      line.rstrip
    when '$'
      size_line = io.gets || raise "Missing Redis bulk string size"
      size = size_line.strip.to_i
      return "" if size < 0

      payload = Bytes.new(size)
      io.read_fully(payload)

      trailer = Bytes.new(2)
      io.read_fully(trailer)

      String.new(payload)
    else
      raise "Unsupported Redis response prefix: #{prefix}"
    end
  end

  def redis_command(host : String, port : Int32, *parts : String) : String
    TCPSocket.open(host, port) do |socket|
      send_redis_command(socket, parts.to_a)
      read_redis_response(socket)
    end
  end

  def redis_command(redis_url : String, *parts : String) : String
    uri = URI.parse(redis_url)
    host = uri.host || raise "Redis URL is missing host"
    port = uri.port || 6379

    TCPSocket.open(host, port) do |socket|
      if password = uri.password
        send_redis_command(socket, ["AUTH", password])
        auth_response = read_redis_response(socket)
        raise "Redis AUTH failed: #{auth_response}" unless auth_response == "OK"
      end

      send_redis_command(socket, parts.to_a)
      read_redis_response(socket)
    end
  end

  describe "Integration: DockerContainer" do
    it "starts and stops a Redis container" do
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)
        .with_name("tc-crystal-test-redis")

      begin
        container.start
        container.running?.should be_true
        container.container_id.should_not be_nil

        host = container.host
        port = container.mapped_port(6379)
        host.should_not be_empty
        port.should be > 0
        redis_command(host, port, "PING").should eq("PONG")
        redis_command(host, port, "SET", "integration:start-stop", "ok").should eq("OK")
        redis_command(host, port, "GET", "integration:start-stop").should eq("ok")

        container.stop
        container.exited?.should be_true
      ensure
        container.remove(force: true) rescue nil
      end
    end

    it "uses block-based container lifecycle" do
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)

      container.use do |c|
        c.running?.should be_true
        c.exists?.should be_true
        port = c.mapped_port(6379)
        port.should be > 0
        redis_command(c.host, port, "PING").should eq("PONG")
      end

      container.exists?.should be_false
      container.container_id.should be_nil
    end

    it "executes commands in the container" do
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)

      begin
        container.start
        output = container.exec(["redis-cli", "SET", "integration:exec", "value-from-exec"])
        output.strip.should eq("OK")
        container.exec(["redis-cli", "GET", "integration:exec"]).strip.should eq("value-from-exec")
        redis_command(container.host, container.mapped_port(6379), "GET", "integration:exec").should eq("value-from-exec")
      ensure
        container.stop rescue nil
        container.remove(force: true) rescue nil
      end
    end

    it "retrieves container logs" do
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)

      begin
        container.start
        sleep 1.second
        logs = container.logs
        logs.should contain("Ready to accept connections")
        logs.should contain("Redis version")
      ensure
        container.stop rescue nil
        container.remove(force: true) rescue nil
      end
    end
  end

  describe "Integration: RedisContainer" do
    it "starts and provides connection URL" do
      container = Testcontainers::RedisContainer.new("redis:7-alpine")
        .with_password("secret")

      begin
        container.start
        container.running?.should be_true
        url = container.redis_url
        url.should start_with("redis://")
        url.should contain(":#{container.mapped_port(6379)}")

        uri = URI.parse(url)
        uri.scheme.should eq("redis")
        uri.host.should eq(container.host)
        uri.port.should eq(container.mapped_port(6379))
        uri.password.should eq("secret")

        redis_command(url, "PING").should eq("PONG")
        redis_command(url, "SET", "integration:redis-container", "ready").should eq("OK")
        redis_command(url, "GET", "integration:redis-container").should eq("ready")
      ensure
        container.stop rescue nil
        container.remove(force: true) rescue nil
      end
    end
  end

  describe "Integration: Network" do
    it "creates and removes a network" do
      network = Testcontainers::Network.new(name: "tc-crystal-test-network")

      begin
        network.create!
        network.created?.should be_true
        network.network_id.should_not be_nil
        network.info.name.should eq(network.name)
        network.info.id.should eq(network.network_id)
      ensure
        network.remove rescue nil
      end

      network.created?.should be_false
    end

    it "applies Testcontainers labels to container and network" do
      network = Testcontainers::Network.new
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)

      begin
        network.create!
        container.start

        container_labels = container.info.config.labels
        container_labels.should_not be_nil
        container_labels = container_labels.not_nil!

        network_labels = network.info.labels

        container_labels["org.testcontainers"].should eq("true")
        network_labels["org.testcontainers"].should eq("true")

        container_labels["org.testcontainers.sessionId"].should eq(Testcontainers::DockerClient::SESSION_ID)
        network_labels["org.testcontainers.sessionId"].should eq(Testcontainers::DockerClient::SESSION_ID)

        container_labels["org.testcontainers.lang"].should eq("crystal")
        network_labels["org.testcontainers.lang"].should eq("crystal")

        container_labels["org.testcontainers.version"].should eq(Testcontainers::VERSION)
        network_labels["org.testcontainers.version"].should eq(Testcontainers::VERSION)
      ensure
        container.stop rescue nil
        container.remove(force: true) rescue nil
        network.remove rescue nil
      end
    end
  end
{% else %}
  describe "Integration tests" do
    pending "skipped - compile with -Dintegration flag to run" { }
  end
{% end %}
