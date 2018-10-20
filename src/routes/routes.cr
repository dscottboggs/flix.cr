# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "parallel"
require "./route_helpers"

module Flix
  extend self

  def serve_up
    8.times do |i|
      pspawn do
        get "/ping" { "pong" }
        get "/dmp" { config.dirs.to_json.tap { |o| Flix.logger.debug "dumping JSON #{o}" } }
        get "/img/:id" { |env| serve_image env }
        get "/img" { |env| serve_image env }
        get "/vid/:id" { |env| serve_video env }
        get "/vid" { |env| serve_video env }
        get "/" { |env| env.redirect "/index.html" }

        public_folder config.webroot
        #
        # Kemal.config do |conf|
        #   conf.port = Flix.config.port.to_i
        # end
        Kemal.run do |conf|
          server = conf.server
          raise "nil server in process #{i}!" if server.nil?
          server.not_nil!.bind_tcp("0.0.0.0", Flix.config.port.to_i, reuse_port: true)
        end
      end
    end
  end
end
