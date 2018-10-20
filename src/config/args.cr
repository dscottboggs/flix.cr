# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "option_parser"

module Flix
  extend self

  # Create a new Configuration from command-line arguments
  def parse_args
    dir_help = "Set a media directory (can be specified multiple times)"
    port_help = "set the port number on which the API should be accessible"
    dirs = Array(String).new
    config_location = ENV["flix_config"]? || File.join(ENV["HOME"], ".config", "flix")
    # TODO: revise default ^^
    port : UInt16 = (ENV["flix_port"]? || 80).to_u16
    OptionParser.parse! do |parser|
      parser.banner =
