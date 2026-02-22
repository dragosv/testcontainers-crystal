module Testcontainers
  # NginxContainer provides a pre-configured container for Nginx.
  #
  # Example:
  # ```
  # container = Testcontainers::NginxContainer.new
  # container.start
  #
  # url = "http://#{container.host}:#{container.mapped_port(80)}"
  #
  # container.stop
  # container.remove
  # ```
  class NginxContainer < DockerContainer
    NGINX_DEFAULT_PORT  = 80
    NGINX_DEFAULT_IMAGE = "nginx:latest"

    def initialize(image : String = NGINX_DEFAULT_IMAGE)
      super(image)
      with_wait_for_http(path: "/", container_port: NGINX_DEFAULT_PORT) unless wait_for_user_defined?
    end

    def start : self
      with_exposed_port(port)
      super
    end

    def port : Int32
      NGINX_DEFAULT_PORT
    end

    # Returns the base URL for the Nginx instance.
    def base_url(protocol : String = "http") : String
      "#{protocol}://#{host}:#{mapped_port(port)}"
    end
  end
end
