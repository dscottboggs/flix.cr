# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "kemal-auth-token"
require "./routes/*"
require "./auth"
require "./scanner/mime_type"

module Flix
  extend self
  include RouteHelpers

  # Begin serving the application
  def serve_up
    serve_up Flix.config.processes
  end

  private def serve_up(procs : Int)
    Flix::MetadataConfig.synchronize!
    (procs - 1).times do
      fork do
        do_serve_up
      rescue e
        STDERR.puts "Fork died!! Excpetion was: #{e.message}\nRespawning..."
        serve_up 1
      end
    end
    do_serve_up
  end

  private def do_serve_up
    add_handler Authentication::Handler.new
    error 404 { "404 not found.\r\n" }
    error 403 { "Forbidden.\r\n" }
    get("/ping") { "pong" }
    # output a representation of the file structure
    get "/dmp" do |ctx|
      next unless user_found?(ctx)
      Flix.logger.debug "got user #{ctx.current_user.inspect}"
      ctx.response.content_type = "application/json"
      Flix.config.dirs.to_json
    end

    get "/scan" do |ctx|
      Flix::MetadataConfig.synchronize!
      ctx.response.puts "OK."
    rescue error : Exception
      ctx.response.status_code = 500
      ctx.response.puts "Error synchronizing files:"
      ctx.response.puts error.message.inspect
    end
    # serve an image
    get "/img" do |ctx|
      serve_img to: ctx
    end
    get "/img/:id" do |ctx|
      serve_img to: ctx
    end
    # serve a video
    get "/vid" do |ctx|
      serve_video to: ctx
    end
    get "/vid/:id" do |ctx|
      serve_video to: ctx
    end
    # serve metadata
    get "/nfo" do |ctx|
      serve_metadata to: ctx
    end
    get "/nfo/:id" do |ctx|
      serve_metadata to: ctx
    end
    # Serve subtitles
    get "/ass" do |ctx|
      serve_subtitles to: ctx
    end
    get "/ass/:id" do |ctx|
      serve_subtitles to: ctx
    end

    # the webroot for the server
    get "/" { |context| context.redirect "/index.html" }

    public_folder Flix.config.webroot
    Kemal.config.env = "production" # unless Flix.config.debug
    if ENV["KEMAL_ENV"]? == "test"
      # kemal-spec only works like this
      Kemal.run
    else
      # http://kemalcr.com/cookbook/reuse_port/
      Kemal.run do |conf|
        if server = conf.server
          if Flix.config.use_ssl?
            ssl = Kemal::SSL.new
            ssl.cert_file = Flix.config.cert_file.not_nil!
            ssl.key_file = Flix.config.key_file.not_nil!
            conf.ssl = ssl.context
            server.bind_tls(
              host: "0.0.0.0",
              port: Flix.config.port.to_i,
              context: conf.ssl.not_nil!,
              reuse_port: Flix.config.processes > 1)
          else
            server.bind_tcp("0.0.0.0", Flix.config.port.to_i, reuse_port: Flix.config.processes > 1)
          end
        else
          raise "got nil server! look at config class"
        end
      end
    end
  end
end
