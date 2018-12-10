# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "parallel"
require "./routes/*"

module Flix
  extend self

  def serve_up
    (config.processes - 1).times { fork { do_serve_up } }
    do_serve_up
  end
  protected def do_serve_up
    add_handler PingHandler.new
    add_handler DumpHandler.new
    add_handler ImageHandler.new
    add_handler VideoHandler.new
    get "/" { |env| env.redirect "/index.html" }

    public_folder config.webroot
    Kemal.run do |conf|
      if server = conf.server
        server.bind_tcp("0.0.0.0", Flix.config.port.to_i, reuse_port: config.processes > 1)
      else
        raise "got nil server! look at config class"
      end
    end
  end
end
