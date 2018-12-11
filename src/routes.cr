# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "kemal-auth-token"
require "./routes/*"
require "./auth"

module Flix
  include Authentication
  extend self

  def serve_up
    (config.processes - 1).times { fork { do_serve_up } }
    do_serve_up
  end

  private def do_serve_up
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

  private def setup_authentication
    auth_handler = Kemal::AuthToken.new
    auth_handler.sign_in do |name, password|
      sign_in_with name, password
    end
    auth_handler.load_user do |jwt_payload|
      get_signed_in_user user_info: jwt_payload
    end
  end
end
