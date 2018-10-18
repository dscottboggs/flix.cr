require "logger"

DEBUG  = true
LOGGER = Logger.new STDOUT, level: DEBUG ? Logger::DEBUG : Logger::WARN
