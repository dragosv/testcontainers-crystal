# Monkey-patch for docr types that are missing JSON::Serializable
# This fixes a bug in docr where ExecConfig doesn't include JSON::Serializable
# even though it has JSON::Field annotations.

module Docr::Types
  class ExecConfig
    include JSON::Serializable
  end
end

# Monkey-patch for Docr::Types::Image to make GraphDriver nilable.
#
# Docker API v1.44+ (Docker 25+) removed the GraphDriver field from image
# inspect responses. The original docr type requires it as non-nilable,
# causing JSON::SerializableError when parsing responses from newer Docker
# versions.
module Docr::Types
  class Image
    @[JSON::Field(key: "GraphDriver")]
    property graph_driver : Docr::Types::GraphDriverData?
  end
end

# Monkey-patch for Docr::Types::ContainerInspectResponse to make GraphDriver
# nilable (same Docker API v1.44+ deprecation as above).
module Docr::Types
  class ContainerInspectResponse
    @[JSON::Field(key: "GraphDriver")]
    property graph_driver : Docr::Types::GraphDriverData?
  end
end

# Monkey-patch for Docr::Client to pool UNIX sockets via http_client.
#
# Crystal's HTTP::Client, when initialized with a custom IO (UNIXSocket),
# sets @reconnect = false. The original Docr::Client creates a single socket
# and reuses it across all requests, which is unreliable when Docker drops
# the connection.
#
# Fix: use the `http_client` shard to handle a connection pool, avoiding
# connection setup overhead for every single request while ensuring resilience.
require "http_client"

# Monkey-patch to expose closed state for DB::Pool to properly evict HTTP::Client connections
class HTTP::Client
  def closed?
    @io.nil?
  end
end

module Docr
  class PoolProxy
    @@pool : HTTPClient::Client?

    def self.pool
      @@pool ||= HTTPClient.new(max_pool_size: 50, checkout_timeout: 10.seconds) do
        HTTP::Client.new(UNIXSocket.new("/var/run/docker.sock"))
      end
    end

    def exec(method, url, headers, body, &)
      retry_count = 0

      loop do
        begin
          return self.class.pool.checkout do |client|
            begin
              client.exec(method, url, headers, body) do |response|
                yield response
              end
            rescue ex : IO::Error | Socket::Error | DB::Error
              client.close
              raise ex
            rescue ex : Exception
              if ex.message.try(&.includes?("This HTTP::Client cannot be reconnected"))
                client.close
              end
              raise ex
            end
          end
        rescue ex : Exception
          if (ex.is_a?(IO::Error) || ex.is_a?(Socket::Error) || ex.message.try(&.includes?("This HTTP::Client cannot be reconnected"))) && retry_count < 3
            retry_count += 1
            next
          else
            raise ex
          end
        end
      end
    end
  end

  class Client
    def initialize
      @client = PoolProxy.new
    end
  end
end

# Monkey-patch for Docr::Endpoints::Containers#logs to fully consume the
# response body inside the HTTP::Client block.
#
# The original implementation returns `response.body_io` via a non-local
# `return` from inside the yielded block. Crystal's HTTP::Client#exec_internal
# has an ensure block that calls `skip_to_end` on body_io and may close the
# connection afterward. This drains the IO and can leave the connection dead.
#
# Fix: read the entire body inside the block and wrap it in an IO::Memory.
module Docr::Endpoints
  class Containers
    def logs(id : String, follow = false, stdout = false, stderr = false, since = 0, _until = 0, timestamps = false, tail = "all")
      params = URI::Params{
        "follow"     => [follow.to_s],
        "stdout"     => [stdout.to_s],
        "stderr"     => [stderr.to_s],
        "since"      => [since.to_s],
        "until"      => [_until.to_s],
        "timestamps" => [timestamps.to_s],
        "tail"       => [tail],
      }

      @client.call("GET", "/containers/#{id}/logs?#{params}") do |response|
        body = response.body_io.gets_to_end
        return IO::Memory.new(body)
      end
    end
  end
end

# Monkey-patch for Docr::Endpoints::Exec#start to fully consume the
# response body inside the HTTP::Client block (same issue as logs above).
module Docr::Endpoints
  class Exec
    def start(id : String, config : Docr::Types::ExecStartConfig) : IO
      headers = HTTP::Headers{
        "Content-Type" => "application/json",
      }

      payload = config.to_json

      @client.call("POST", "/exec/#{id}/start", headers, payload) do |response|
        body = response.body_io.gets_to_end
        return IO::Memory.new(body)
      end
    end
  end
end
