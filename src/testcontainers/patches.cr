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

# Monkey-patch for Docr::Client to use a fresh socket per request.
#
# Crystal's HTTP::Client, when initialized with a custom IO (UNIXSocket),
# sets @reconnect = false. After certain responses (e.g. Connection: close,
# or when body_io cleanup runs in HTTP::Client's ensure block), the internal
# @io is set to nil. Subsequent requests then fail with "This HTTP::Client
# cannot be reconnected" since the client cannot re-establish the socket.
#
# The original Docr::Client creates a single socket in initialize and reuses
# it across all requests. This is unreliable over UNIX sockets where Docker
# may close the connection at any time.
#
# Fix: create a fresh UNIXSocket + HTTP::Client for every API call. This
# eliminates all connection state issues between requests. The overhead of
# reconnecting a local UNIX socket per request is negligible for test usage.
module Docr
  class Client
    def call(method : String, url : String | URI, headers : HTTP::Headers | Nil = nil, body : IO | Slice(UInt8) | String | Nil = nil, &)
      socket = UNIXSocket.new("/var/run/docker.sock")
      client = HTTP::Client.new(socket)

      client.exec(method, url, headers, body) do |response|
        unless response.success?
          body_text = response.body_io?.try(&.gets_to_end) || "{\"message\": \"No response body\"}"
          error = Docr::Types::ErrorResponse.from_json(body_text)
          raise Docr::Errors::DockerAPIError.new(error.message, response.status_code)
        end

        yield response
      end
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
