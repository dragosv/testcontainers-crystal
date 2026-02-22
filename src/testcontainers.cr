require "docr"
require "log"
require "socket"
require "http/client"
require "uri"
require "uuid"

require "./testcontainers/patches"
require "./testcontainers/version"
require "./testcontainers/errors"
require "./testcontainers/logger"
require "./testcontainers/docker_client"
require "./testcontainers/docker_container"
require "./testcontainers/network"
require "./testcontainers/containers/*"

module Testcontainers
end
