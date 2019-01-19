# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
# TODO: Write documentation for `Flix`
require "./core_ext/**"
require "logger"
require "./config/*"
require "./scanner/*"
require "./routes"

module Flix
  VERSION = "0.1.0"

  @@config : Configuration?
  @@preconfig_logger : Logger? = Logger.new STDOUT, level: Logger::DEBUG

  def config
    if @@config.nil?
      @@config = Configuration.from_args ARGV
    else
      @@config.not_nil!
    end
  end

  def config=(@@config)
  end

  # relevant function
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
