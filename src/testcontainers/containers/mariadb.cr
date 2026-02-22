module Testcontainers
  # MariadbContainer provides a pre-configured container for MariaDB.
  #
  # Example:
  # ```
  # container = Testcontainers::MariadbContainer.new
  # container.start
  #
  # url = container.database_url
  # # => "mysql://test:test@localhost:32768/test"
  #
  # container.stop
  # container.remove
  # ```
  class MariadbContainer < DockerContainer
    MARIADB_DEFAULT_PORT          = 3306
    MARIADB_DEFAULT_IMAGE         = "mariadb:latest"
    MARIADB_DEFAULT_ROOT_PASSWORD = "test"
    MARIADB_DEFAULT_USERNAME      = "test"
    MARIADB_DEFAULT_PASSWORD      = "test"
    MARIADB_DEFAULT_DATABASE      = "test"

    getter root_password : String
    getter username : String
    getter password : String
    getter database : String

    def initialize(
      image : String = MARIADB_DEFAULT_IMAGE,
      @root_password : String = ENV.fetch("MARIADB_ROOT_PASSWORD", MARIADB_DEFAULT_ROOT_PASSWORD),
      @username : String = ENV.fetch("MARIADB_USER", MARIADB_DEFAULT_USERNAME),
      @password : String = ENV.fetch("MARIADB_PASSWORD", MARIADB_DEFAULT_PASSWORD),
      @database : String = ENV.fetch("MARIADB_DATABASE", MARIADB_DEFAULT_DATABASE)
    )
      super(image)
      with_healthcheck(
        test: "healthcheck.sh --connect --innodb_initialized",
        interval: 2.0,
        timeout: 5.0,
        retries: 10,
        shell: true,
      )
      with_wait_for_healthcheck unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(port)
      configure_env
      super
    end

    def port : Int32
      MARIADB_DEFAULT_PORT
    end

    def with_root_password(root_password : String) : self
      @root_password = root_password
      self
    end

    def with_database(database : String) : self
      @database = database
      self
    end

    def with_username(username : String) : self
      @username = username
      self
    end

    def with_password(password : String) : self
      @password = password
      self
    end

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
      with_env("MARIADB_ROOT_PASSWORD", @root_password)
      with_env("MARIADB_USER", @username)
      with_env("MARIADB_PASSWORD", @password)
      with_env("MARIADB_DATABASE", @database)
    end
  end
end
