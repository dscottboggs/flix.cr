require "./core_ext/**"
require "logger"
require "./config/*"
require "./scanner/*"
require "./routes"

# The Flix video streaming server is a lightweight, fast, and minimalist video
# streaming service, which provides an optional web interface.
# [See it in action!](https://demo.flix.tams.tech)
#
# Copyright (C) 2018 D. Scott Boggs
#
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  VERSION = "0.1.0"

  @@config : Configuration?
  @@preconfig_logger : Logger? = Logger.new STDOUT, level: Logger::DEBUG

  # Lazily load configuration from arguments to allow intercepting by tests
  def config
    @@config ||= Configuration.from_args ARGV
  end

  # Set the configuration to an already initialized Flix::Configuration object.
  def config=(@@config)
  end

  # A central logging service.
  def logger
    if @@config.nil?
      @@preconfig_logger.not_nil!
    else
      @@preconfig_logger = nil
      config.logger
    end
  end

  serve_up
end
