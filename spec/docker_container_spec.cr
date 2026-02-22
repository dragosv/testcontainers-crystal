require "./spec_helper"

describe Testcontainers::DockerContainer do
  describe "#initialize" do
    it "creates a container with the given image" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      container.image.should eq("redis:latest")
    end

    it "sets default labels" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      container.labels["org.testcontainers.lang"].should eq("crystal")
      container.labels["org.testcontainers.version"].should eq(Testcontainers::VERSION)
    end

    it "starts with empty configurations" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      container.name.should be_nil
      container.command.should be_nil
      container.entrypoint.should be_nil
      container.exposed_ports.should be_empty
      container.port_bindings.should be_empty
      container.volumes.should be_empty
      container.filesystem_binds.should be_empty
      container.env.should be_empty
      container.working_dir.should be_nil
      container.healthcheck.should be_nil
      container.container_id.should be_nil
    end
  end

  describe "#with_name" do
    it "sets the container name" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_name("my-redis")
      container.name.should eq("my-redis")
    end
  end

  describe "#with_command" do
    it "sets the command from variadic args" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_command("redis-server", "--appendonly", "yes")
      container.command.should eq(["redis-server", "--appendonly", "yes"])
    end

    it "sets the command from an array" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_command(["redis-server", "--appendonly", "yes"])
      container.command.should eq(["redis-server", "--appendonly", "yes"])
    end
  end

  describe "#with_entrypoint" do
    it "sets the entrypoint" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_entrypoint("/bin/sh", "-c")
      container.entrypoint.should eq(["/bin/sh", "-c"])
    end
  end

  describe "#with_exposed_port" do
    it "adds an exposed port" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_exposed_port(6379)
      container.exposed_ports.has_key?("6379/tcp").should be_true
      container.port_bindings.has_key?("6379/tcp").should be_true
    end

    it "normalizes string ports" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_exposed_port("6379")
      container.exposed_ports.has_key?("6379/tcp").should be_true
    end

    it "preserves protocol in port string" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_exposed_port("6379/udp")
      container.exposed_ports.has_key?("6379/udp").should be_true
    end
  end

  describe "#with_exposed_ports" do
    it "adds multiple exposed ports" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_exposed_ports(6379, 6380)
      container.exposed_ports.size.should eq(2)
      container.exposed_ports.has_key?("6379/tcp").should be_true
      container.exposed_ports.has_key?("6380/tcp").should be_true
    end
  end

  describe "#with_fixed_exposed_port" do
    it "maps container port to host port" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_fixed_exposed_port(6379, 16379)
      container.exposed_ports.has_key?("6379/tcp").should be_true
      bindings = container.port_bindings["6379/tcp"]
      bindings.first.host_port.should eq("16379")
    end
  end

  describe "#with_env" do
    it "sets environment from key-value pair" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_env("REDIS_PASSWORD", "secret")
      container.env.should contain("REDIS_PASSWORD=secret")
    end

    it "sets environment from hash" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_env({"KEY1" => "val1", "KEY2" => "val2"})
      container.env.should contain("KEY1=val1")
      container.env.should contain("KEY2=val2")
    end

    it "sets environment from array" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_env(["KEY1=val1", "KEY2=val2"])
      container.env.should contain("KEY1=val1")
      container.env.should contain("KEY2=val2")
    end
  end

  describe "#with_working_dir" do
    it "sets the working directory" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_working_dir("/app")
      container.working_dir.should eq("/app")
    end
  end

  describe "#with_volume" do
    it "adds a volume" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_volume("/data")
      container.volumes.has_key?("/data").should be_true
    end
  end

  describe "#with_filesystem_bind" do
    it "adds a filesystem bind" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_filesystem_bind("/host/path", "/container/path", "ro")
      container.filesystem_binds.should contain("/host/path:/container/path:ro")
      container.volumes.has_key?("/container/path").should be_true
    end
  end

  describe "#with_labels" do
    it "adds labels" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_labels({"app" => "test", "env" => "ci"})
      container.labels["app"].should eq("test")
      container.labels["env"].should eq("ci")
    end
  end

  describe "#with_label" do
    it "adds a single label" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_label("app", "test")
      container.labels["app"].should eq("test")
    end
  end

  describe "#with_healthcheck" do
    it "configures a healthcheck" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_healthcheck(
          test: "redis-cli ping",
          interval: 5.0,
          timeout: 3.0,
          retries: 3,
          shell: true,
        )
      hc = container.healthcheck.not_nil!
      hc.test.not_nil!.first.should eq("CMD-SHELL")
      hc.interval.should eq(5_000_000_000_i64)
      hc.timeout.should eq(3_000_000_000_i64)
      hc.retries.should eq(3_i64)
    end

    it "uses CMD prefix when shell is false" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_healthcheck(
          test: ["redis-cli", "ping"],
          shell: false,
        )
      hc = container.healthcheck.not_nil!
      hc.test.not_nil!.first.should eq("CMD")
    end
  end

  describe "#get_env" do
    it "returns the value of an env variable" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_env("MY_KEY", "my_value")
      container.get_env("MY_KEY").should eq("my_value")
    end

    it "returns nil for missing env variable" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      container.get_env("NONEXISTENT").should be_nil
    end
  end

  describe "#wait_for_user_defined?" do
    it "returns false by default" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      container.wait_for_user_defined?.should be_false
    end

    it "returns true after setting a wait strategy" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_wait_for_logs(/ready/)
      container.wait_for_user_defined?.should be_true
    end
  end

  describe "fluent API chaining" do
    it "supports method chaining" do
      container = Testcontainers::DockerContainer.new("redis:latest")
        .with_name("test-redis")
        .with_exposed_port(6379)
        .with_env("KEY", "VALUE")
        .with_label("app", "test")
        .with_working_dir("/app")

      container.name.should eq("test-redis")
      container.exposed_ports.has_key?("6379/tcp").should be_true
      container.env.should contain("KEY=VALUE")
      container.labels["app"].should eq("test")
      container.working_dir.should eq("/app")
    end
  end

  describe "container not started errors" do
    it "raises ContainerNotStartedError for status when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.status
      end
    end

    it "raises ContainerNotStartedError for stop when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.stop
      end
    end

    it "raises ContainerNotStartedError for logs when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.logs
      end
    end

    it "raises ContainerNotStartedError for mapped_port when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.mapped_port(6379)
      end
    end

    it "raises ContainerNotStartedError for host when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.host
      end
    end

    it "raises ContainerNotStartedError for exec when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.exec(["echo", "hello"])
      end
    end

    it "raises ContainerNotStartedError for info when not started" do
      container = Testcontainers::DockerContainer.new("redis:latest")
      expect_raises(Testcontainers::ContainerNotStartedError) do
        container.info
      end
    end
  end

  describe "GenericContainer alias" do
    it "is an alias for DockerContainer" do
      container = Testcontainers::GenericContainer.new("redis:latest")
      container.should be_a(Testcontainers::DockerContainer)
    end
  end
end
