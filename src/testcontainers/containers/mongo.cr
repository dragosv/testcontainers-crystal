module Testcontainers
  # MongoContainer provides a pre-configured container for MongoDB.
  #
  # Example:
  # ```
  # container = Testcontainers::MongoContainer.new
  # container.start
  #
  # url = container.connection_url
  # # => "mongodb://test:test@localhost:32768"
  #
  # container.stop
  # container.remove
  # ```
  class MongoContainer < DockerContainer
    MONGO_DEFAULT_PORT     = 27017
    MONGO_DEFAULT_IMAGE    = "mongo:latest"
    MONGO_DEFAULT_USERNAME = "test"
    MONGO_DEFAULT_PASSWORD = "test"
    MONGO_DEFAULT_DATABASE = "test"

    getter username : String?
    getter password : String?
    getter database : String

    def initialize(
      image : String = MONGO_DEFAULT_IMAGE,
      @username : String? = nil,
      @password : String? = nil,
      @database : String = ENV.fetch("MONGO_DATABASE", MONGO_DEFAULT_DATABASE),
    )
      super(image)
      with_wait_for_logs(/Waiting for connections|ready for connections/) unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(port)
      configure_env
      super
    end

    def port : Int32
      MONGO_DEFAULT_PORT
    end

    def with_username(username : String) : self
      @username = username
      self
    end

    def with_password(password : String) : self
      @password = password
      self
    end

    def with_database(database : String) : self
      @database = database
      self
    end

    # Returns the MongoDB connection URL.
    def connection_url(
      protocol : String = "mongodb",
      username : String? = nil,
      password : String? = nil,
      database : String? = nil,
      options : Hash(String, String) = Hash(String, String).new,
    ) : String
      user = username || @username
      pwd = password || @password
      db = database || @database
      query = options.empty? ? "" : "?#{URI::Params.encode(options)}"

      if user && pwd
        "#{protocol}://#{user}:#{pwd}@#{host}:#{mapped_port(port)}/#{db}#{query}"
      else
        "#{protocol}://#{host}:#{mapped_port(port)}/#{db}#{query}"
      end
    end

    def database_url : String
      connection_url
    end

    private def configure_env
      if user = @username
        with_env("MONGO_INITDB_ROOT_USERNAME", user)
      end
      if pwd = @password
        with_env("MONGO_INITDB_ROOT_PASSWORD", pwd)
      end
      with_env("MONGO_INITDB_DATABASE", @database)
    end
  end
end
