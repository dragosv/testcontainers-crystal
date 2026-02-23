module Testcontainers
  # PostgresContainer provides a pre-configured container for PostgreSQL.
  #
  # Example:
  # ```
  # container = Testcontainers::PostgresContainer.new
  # container.start
  #
  # url = container.database_url
  # # => "postgres://test:test@localhost:32768/test"
  #
  # container.stop
  # container.remove
  # ```
  class PostgresContainer < DockerContainer
    POSTGRES_DEFAULT_PORT     = 5432
    POSTGRES_DEFAULT_IMAGE    = "postgres:latest"
    POSTGRES_DEFAULT_USERNAME = "test"
    POSTGRES_DEFAULT_PASSWORD = "test"
    POSTGRES_DEFAULT_DATABASE = "test"

    getter username : String
    getter password : String
    getter database : String

    def initialize(
      image : String = POSTGRES_DEFAULT_IMAGE,
      @username : String = ENV.fetch("POSTGRES_USER", POSTGRES_DEFAULT_USERNAME),
      @password : String = ENV.fetch("POSTGRES_PASSWORD", POSTGRES_DEFAULT_PASSWORD),
      @database : String = ENV.fetch("POSTGRES_DATABASE", POSTGRES_DEFAULT_DATABASE),
    )
      super(image)
      with_healthcheck(
        test: ["pg_isready", "-U", @username, "-d", @database],
        interval: 1.0,
        timeout: 5.0,
        retries: 5,
        shell: false
      )
      with_wait_for_healthcheck unless wait_for_user_defined?
    end

    # Starts the container.
    def start : self
      with_exposed_port(port)
      configure_env
      super
    end

    # Returns the default port.
    def port : Int32
      POSTGRES_DEFAULT_PORT
    end

    # Sets the database name.
    def with_database(database : String) : self
      @database = database
      self
    end

    # Sets the username.
    def with_username(username : String) : self
      @username = username
      self
    end

    # Sets the password.
    def with_password(password : String) : self
      @password = password
      self
    end

    # Returns the database URL.
    #
    # Example: "postgres://user:password@localhost:5432/dbname"
    def database_url(
      protocol : String = "postgres",
      username : String? = nil,
      password : String? = nil,
      database : String? = nil,
      options : Hash(String, String) = Hash(String, String).new,
    ) : String
      db = database || @database
      user = username || @username
      pwd = password || @password
      query = options.empty? ? "" : "?#{URI::Params.encode(options)}"
      "#{protocol}://#{user}:#{pwd}@#{host}:#{mapped_port(port)}/#{db}#{query}"
    end

    private def configure_env
      with_env("POSTGRES_USER", @username)
      with_env("POSTGRES_PASSWORD", @password)
      with_env("POSTGRES_DB", @database)
    end
  end
end
