module Testcontainers
  # RedisContainer provides a pre-configured container for Redis.
  #
  # Example:
  # ```
  # container = Testcontainers::RedisContainer.new
  # container.start
  #
  # host = container.host
  # port = container.mapped_port(6379)
  # url = container.redis_url
  #
  # container.stop
  # container.remove
  # ```
  class RedisContainer < DockerContainer
    REDIS_DEFAULT_PORT  = 6379
    REDIS_DEFAULT_IMAGE = "redis:latest"

    getter password : String?

    def initialize(
      image : String = REDIS_DEFAULT_IMAGE,
      @password : String? = nil,
    )
      super(image)
      with_wait_for_logs(/Ready to accept connections/) unless wait_for_user_defined?
    end

    # Starts the container with the default Redis port exposed.
    def start : self
      with_exposed_port(port)
      if pwd = @password
        with_command("redis-server", "--requirepass", pwd)
      end
      super
    end

    # Returns the default Redis port.
    def port : Int32
      REDIS_DEFAULT_PORT
    end

    # Sets the password for Redis.
    def with_password(password : String) : self
      @password = password
      self
    end

    # Returns the Redis connection URL.
    #
    # Example: "redis://:password@localhost:6379/0" or "redis://localhost:6379/0"
    def redis_url(protocol : String = "redis", db : Int32 = 0) : String
      if pwd = @password
        "#{protocol}://:#{pwd}@#{host}:#{mapped_port(port)}/#{db}"
      else
        "#{protocol}://#{host}:#{mapped_port(port)}/#{db}"
      end
    end

    # Alias for redis_url.
    def database_url : String
      redis_url
    end
  end
end
