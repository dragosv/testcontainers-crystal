require "docr"
require "uuid"

module Testcontainers
  # DockerClient provides a singleton-like access to the Docr API client
  # which communicates with the Docker daemon via the UNIX socket.
  module DockerClient
    @@api : Docr::API? = nil

    TESTCONTAINERS_LABEL            = "org.testcontainers"
    TESTCONTAINERS_SESSION_ID_LABEL = "#{TESTCONTAINERS_LABEL}.sessionId"
    TESTCONTAINERS_LANG_LABEL       = "#{TESTCONTAINERS_LABEL}.lang"
    TESTCONTAINERS_VERSION_LABEL    = "#{TESTCONTAINERS_LABEL}.version"

    SESSION_ID = UUID.random.to_s

    # Returns the shared Docr::API instance, creating it if needed.
    #
    # The API instance uses the Docker socket at /var/run/docker.sock
    # or the path specified by the DOCKER_HOST environment variable.
    def self.api : Docr::API
      @@api ||= begin
        client = Docr::Client.new
        Docr::API.new(client)
      end
    end

    # Resets the cached API instance. Useful for testing.
    def self.reset! : Nil
      @@api = nil
    end

    # Returns the default marker labels applied to Testcontainers resources.
    def self.default_labels : Hash(String, String)
      {
        TESTCONTAINERS_LABEL            => "true",
        TESTCONTAINERS_SESSION_ID_LABEL => SESSION_ID,
        TESTCONTAINERS_LANG_LABEL       => "crystal",
        TESTCONTAINERS_VERSION_LABEL    => Testcontainers::VERSION,
      }
    end

    # Returns the Docker host address.
    #
    # Resolution order:
    # 1. TC_HOST environment variable
    # 2. DOCKER_HOST environment variable (parsed)
    # 3. "localhost" as fallback
    def self.host : String
      if tc_host = ENV["TC_HOST"]?
        return tc_host
      end

      if docker_host = ENV["DOCKER_HOST"]?
        uri = URI.parse(docker_host)
        case uri.scheme
        when "tcp", "http", "https"
          return uri.host || "localhost"
        end
      end

      "localhost"
    end

    # Returns true if the current process is running inside a Docker container
    def self.inside_container? : Bool
      File.exists?("/.dockerenv")
    end
  end
end
