require "./spec_helper"

describe Testcontainers::Network do
  describe "#initialize" do
    it "generates a unique name by default" do
      network = Testcontainers::Network.new
      network.name.should start_with("testcontainers-network-")
    end

    it "uses the given name" do
      network = Testcontainers::Network.new(name: "my-network")
      network.name.should eq("my-network")
    end

    it "defaults to bridge driver" do
      network = Testcontainers::Network.new
      network.driver.should eq("bridge")
    end

    it "starts not created" do
      network = Testcontainers::Network.new
      network.created?.should be_false
      network.network_id.should be_nil
    end
  end

  describe ".generate_name" do
    it "generates unique names" do
      name1 = Testcontainers::Network.generate_name
      name2 = Testcontainers::Network.generate_name
      name1.should_not eq(name2)
      name1.should start_with("testcontainers-network-")
    end
  end
end
