module Testcontainers
  # ElasticsearchContainer provides a pre-configured container for Elasticsearch.
  #
  # Example:
  # ```
  # container = Testcontainers::ElasticsearchContainer.new
  # container.start
  #
  # url = container.elasticsearch_url
  # # => "http://localhost:32768"
  #
  # container.stop
  # container.remove
  # ```
  class ElasticsearchContainer < DockerContainer
    ES_DEFAULT_PORT  = 9200
    ES_DEFAULT_IMAGE = "elasticsearch:8.11.0"
    ES_DEFAULT_PASSWORD = "test"

    getter password : String

    def initialize(
      image : String = ES_DEFAULT_IMAGE,
      @password : String = ENV.fetch("ELASTIC_PASSWORD", ES_DEFAULT_PASSWORD)
    )
      super(image)
      with_wait_for_http(
        path: "/_cluster/health",
        container_port: ES_DEFAULT_PORT,
        status: 200,
      ) unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(port)
      configure_env
      super
    end

    def port : Int32
      ES_DEFAULT_PORT
    end

    def with_password(password : String) : self
      @password = password
      self
    end

    # Returns the Elasticsearch URL.
    def elasticsearch_url(protocol : String = "http") : String
      "#{protocol}://#{host}:#{mapped_port(port)}"
    end

    private def configure_env
      with_env("discovery.type", "single-node")
      with_env("ELASTIC_PASSWORD", @password)
      with_env("xpack.security.enabled", "false")
    end
  end
end
