require "./spec_helper"

describe Testcontainers::RedisContainer do
  describe "#initialize" do
    it "uses default image" do
      container = Testcontainers::RedisContainer.new
      container.image.should eq("redis:latest")
    end

    it "uses custom image" do
      container = Testcontainers::RedisContainer.new("redis:7-alpine")
      container.image.should eq("redis:7-alpine")
    end

    it "returns correct default port" do
      container = Testcontainers::RedisContainer.new
      container.port.should eq(6379)
    end

    it "sets wait strategy by default" do
      container = Testcontainers::RedisContainer.new
      container.wait_for.should_not be_nil
    end
  end

  describe "#with_password" do
    it "sets the password" do
      container = Testcontainers::RedisContainer.new
        .with_password("secret")
      container.password.should eq("secret")
    end
  end
end

describe Testcontainers::PostgresContainer do
  describe "#initialize" do
    it "uses default image and credentials" do
      container = Testcontainers::PostgresContainer.new
      container.image.should eq("postgres:latest")
      container.username.should eq("test")
      container.password.should eq("test")
      container.database.should eq("test")
    end

    it "uses custom credentials" do
      container = Testcontainers::PostgresContainer.new(
        username: "admin",
        password: "s3cret",
        database: "mydb",
      )
      container.username.should eq("admin")
      container.password.should eq("s3cret")
      container.database.should eq("mydb")
    end

    it "returns correct default port" do
      container = Testcontainers::PostgresContainer.new
      container.port.should eq(5432)
    end

    it "has a healthcheck configured" do
      container = Testcontainers::PostgresContainer.new
      container.healthcheck.should_not be_nil
    end
  end

  describe "fluent setters" do
    it "supports with_database" do
      container = Testcontainers::PostgresContainer.new
        .with_database("custom_db")
      container.database.should eq("custom_db")
    end

    it "supports with_username" do
      container = Testcontainers::PostgresContainer.new
        .with_username("custom_user")
      container.username.should eq("custom_user")
    end

    it "supports with_password" do
      container = Testcontainers::PostgresContainer.new
        .with_password("custom_pass")
      container.password.should eq("custom_pass")
    end
  end
end

describe Testcontainers::MysqlContainer do
  describe "#initialize" do
    it "uses default image and credentials" do
      container = Testcontainers::MysqlContainer.new
      container.image.should eq("mysql:latest")
      container.username.should eq("test")
      container.password.should eq("test")
      container.database.should eq("test")
      container.root_password.should eq("test")
    end

    it "returns correct default port" do
      container = Testcontainers::MysqlContainer.new
      container.port.should eq(3306)
    end
  end
end

describe Testcontainers::MariadbContainer do
  describe "#initialize" do
    it "uses default image and credentials" do
      container = Testcontainers::MariadbContainer.new
      container.image.should eq("mariadb:latest")
      container.username.should eq("test")
      container.password.should eq("test")
      container.database.should eq("test")
    end

    it "returns correct default port" do
      container = Testcontainers::MariadbContainer.new
      container.port.should eq(3306)
    end
  end
end

describe Testcontainers::MongoContainer do
  describe "#initialize" do
    it "uses default image" do
      container = Testcontainers::MongoContainer.new
      container.image.should eq("mongo:latest")
    end

    it "returns correct default port" do
      container = Testcontainers::MongoContainer.new
      container.port.should eq(27017)
    end
  end
end

describe Testcontainers::NginxContainer do
  describe "#initialize" do
    it "uses default image" do
      container = Testcontainers::NginxContainer.new
      container.image.should eq("nginx:latest")
    end

    it "returns correct default port" do
      container = Testcontainers::NginxContainer.new
      container.port.should eq(80)
    end
  end
end

describe Testcontainers::RabbitmqContainer do
  describe "#initialize" do
    it "uses default image and credentials" do
      container = Testcontainers::RabbitmqContainer.new
      container.image.should eq("rabbitmq:management")
      container.username.should eq("guest")
      container.password.should eq("guest")
      container.vhost.should eq("/")
    end

    it "returns correct default port" do
      container = Testcontainers::RabbitmqContainer.new
      container.port.should eq(5672)
    end

    it "returns correct management port" do
      container = Testcontainers::RabbitmqContainer.new
      container.management_port.should eq(15672)
    end
  end
end

describe Testcontainers::ElasticsearchContainer do
  describe "#initialize" do
    it "uses default image" do
      container = Testcontainers::ElasticsearchContainer.new
      container.image.should eq("elasticsearch:8.11.0")
    end

    it "returns correct default port" do
      container = Testcontainers::ElasticsearchContainer.new
      container.port.should eq(9200)
    end
  end
end
