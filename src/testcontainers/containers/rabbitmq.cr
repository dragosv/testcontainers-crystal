module Testcontainers
  # RabbitmqContainer provides a pre-configured container for RabbitMQ.
  #
  # Example:
  # ```
  # container = Testcontainers::RabbitmqContainer.new
  # container.start
  #
  # url = container.connection_url
  # # => "amqp://guest:guest@localhost:32768"
  #
  # container.stop
  # container.remove
  # ```
  class RabbitmqContainer < DockerContainer
    RABBITMQ_DEFAULT_PORT     =  5672
    RABBITMQ_MANAGEMENT_PORT  = 15672
    RABBITMQ_DEFAULT_IMAGE    = "rabbitmq:management"
    RABBITMQ_DEFAULT_USERNAME = "guest"
    RABBITMQ_DEFAULT_PASSWORD = "guest"
    RABBITMQ_DEFAULT_VHOST    = "/"

    getter username : String
    getter password : String
    getter vhost : String

    def initialize(
      image : String = RABBITMQ_DEFAULT_IMAGE,
      @username : String = ENV.fetch("RABBITMQ_DEFAULT_USER", RABBITMQ_DEFAULT_USERNAME),
      @password : String = ENV.fetch("RABBITMQ_DEFAULT_PASS", RABBITMQ_DEFAULT_PASSWORD),
      @vhost : String = ENV.fetch("RABBITMQ_DEFAULT_VHOST", RABBITMQ_DEFAULT_VHOST),
    )
      super(image)
      with_wait_for_logs(/Server startup complete/) unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(RABBITMQ_DEFAULT_PORT)
      with_exposed_port(RABBITMQ_MANAGEMENT_PORT)
      configure_env
      super
    end

    def port : Int32
      RABBITMQ_DEFAULT_PORT
    end

    def management_port : Int32
      RABBITMQ_MANAGEMENT_PORT
    end

    def with_username(username : String) : self
      @username = username
      self
    end

    def with_password(password : String) : self
      @password = password
      self
    end

    def with_vhost(vhost : String) : self
      @vhost = vhost
      self
    end

    # Returns the AMQP connection URL.
    def connection_url(
      protocol : String = "amqp",
      username : String? = nil,
      password : String? = nil,
      vhost : String? = nil,
    ) : String
      user = username || @username
      pwd = password || @password
      vh = vhost || @vhost
      encoded_vhost = vh == "/" ? "" : "/#{vh}"
      "#{protocol}://#{user}:#{pwd}@#{host}:#{mapped_port(port)}#{encoded_vhost}"
    end

    # Returns the management UI URL.
    def management_url : String
      "http://#{host}:#{mapped_port(RABBITMQ_MANAGEMENT_PORT)}"
    end

    private def configure_env
      with_env("RABBITMQ_DEFAULT_USER", @username)
      with_env("RABBITMQ_DEFAULT_PASS", @password)
      with_env("RABBITMQ_DEFAULT_VHOST", @vhost)
    end
  end
end
