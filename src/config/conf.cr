require "logger"
require "./args"

module Flix
  module Scanner
    extend self

    CONFIG = Configuration.parse_args
  end
end
