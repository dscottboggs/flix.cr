# TODO: Write documentation for `Flix`
require "logger"
require "./config/*"
require "./scanner/*"
require "./routes/routes"

module Flix
  VERSION = "0.1.0"

  @@config : Configuration?
  @@preconfig_logger : Logger? = Logger.new STDOUT, level: Logger::DEBUG

  def config
    if @@config.nil?
      @@config = parse_args
    else
      @@config.not_nil!
    end
  end

  def config=(conf : Configuration)
    @@config = conf
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

  serve_up unless ENV["FLIX_DEBUG"]?
end
