require "./spec_helper"

# Integration tests that require a running Docker daemon.
# These tests actually start/stop containers, so they are tagged.
#
# Run with: crystal spec spec/integration_spec.cr
#
# Note: These tests require Docker to be running and accessible
# via /var/run/docker.sock

{% if flag?(:integration) %}
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
        c.mapped_port(6379).should be > 0
      end

      container.exists?.should be_false
    end

    it "executes commands in the container" do
      container = Testcontainers::DockerContainer.new("redis:7-alpine")
        .with_exposed_port(6379)

      begin
        container.start
        output = container.exec(["redis-cli", "ping"])
        output.strip.should eq("PONG")
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
        sleep 1 # Give the container a moment to produce logs
        logs = container.logs
        logs.should contain("Ready to accept connections")
      ensure
        container.stop rescue nil
        container.remove(force: true) rescue nil
      end
    end
  end

  describe "Integration: RedisContainer" do
    it "starts and provides connection URL" do
      container = Testcontainers::RedisContainer.new("redis:7-alpine")

      begin
        container.start
        container.running?.should be_true
        url = container.redis_url
        url.should start_with("redis://")
        url.should contain(":#{container.mapped_port(6379)}")
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
      ensure
        network.remove rescue nil
      end
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
