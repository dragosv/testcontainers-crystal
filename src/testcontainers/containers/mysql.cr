module Testcontainers
  # MysqlContainer provides a pre-configured container for MySQL.
  #
  # Example:
  # ```
  # container = Testcontainers::MysqlContainer.new
  # container.start
  #
  # url = container.database_url
  # # => "mysql://test:test@localhost:32768/test"
  #
  # container.stop
  # container.remove
  # ```
  class MysqlContainer < DockerContainer
    MYSQL_DEFAULT_PORT          = 3306
    MYSQL_DEFAULT_IMAGE         = "mysql:latest"
    MYSQL_DEFAULT_ROOT_PASSWORD = "test"
    MYSQL_DEFAULT_USERNAME      = "test"
    MYSQL_DEFAULT_PASSWORD      = "test"
    MYSQL_DEFAULT_DATABASE      = "test"

    getter root_password : String
    getter username : String
    getter password : String
    getter database : String

    def initialize(
      image : String = MYSQL_DEFAULT_IMAGE,
      @root_password : String = ENV.fetch("MYSQL_ROOT_PASSWORD", MYSQL_DEFAULT_ROOT_PASSWORD),
      @username : String = ENV.fetch("MYSQL_USER", MYSQL_DEFAULT_USERNAME),
      @password : String = ENV.fetch("MYSQL_PASSWORD", MYSQL_DEFAULT_PASSWORD),
      @database : String = ENV.fetch("MYSQL_DATABASE", MYSQL_DEFAULT_DATABASE)
    )
      super(image)
      with_healthcheck(
        test: "mysqladmin ping -h localhost",
        interval: 2.0,
        timeout: 5.0,
        retries: 10,
        shell: true,
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
      MYSQL_DEFAULT_PORT
    end

    # Sets the root password.
    def with_root_password(root_password : String) : self
      @root_password = root_password
      self
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
    def database_url(
      protocol : String = "mysql",
      username : String? = nil,
      password : String? = nil,
      database : String? = nil,
      options : Hash(String, String) = Hash(String, String).new
    ) : String
      db = database || @database
      user = username || @username
      pwd = password || @password
      query = options.empty? ? "" : "?#{URI::Params.encode(options)}"
      "#{protocol}://#{user}:#{pwd}@#{host}:#{mapped_port(port)}/#{db}#{query}"
    end

    private def configure_env
      with_env("MYSQL_ROOT_PASSWORD", @root_password)
      with_env("MYSQL_USER", @username)
      with_env("MYSQL_PASSWORD", @password)
      with_env("MYSQL_DATABASE", @database)
    end
  end
end
