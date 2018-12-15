# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "kemal-auth-token"
require "./routes/*"
require "./auth"

module Flix
  extend self

  def serve_up
    (config.processes - 1).times { fork { do_serve_up } }
    do_serve_up
  end

  private def do_serve_up
    get("/ping") { "pong" }
    # output a representation of the file structure
    get("/dmp") { Flix.config.dirs.to_json }
    # serve an image
    get "/img/:id" do |env|
      id = env.params.url["id"]? || env.params.query["id"]?
      if id.nil?
        render_404
        next
      end
      # try grabbing it as a thumbnail for a video first.
      if (video = Scanner::FileMetadata.all_videos[id]?) &&
         (photo = video.thumbnail) &&
         (File.exists? photo.path)
        send_file env, path: photo.path, mime_type: photo.mime_type.to_s
      elsif (photo = Scanner::FileMetadata.all_photos[id]?) &&
            (File.exists? photo.path)
        send_file env, path: photo.path, mime_type: photo.mime_type.to_s
      else
        render_404
      end
    end
    # serve a video
    get "/vid/:id" do |env|
      id = env.params.url["id"]? || env.params.query["id"]?
      if id.nil?
        render_404
        next
      end
      if video = Scanner::FileMetadata.all_videos[id]?
        Flix.logger.debug "rendering video #{video.path}"
        send_file env, path: video.path, mime_type: video.mime_type.to_s
      else
        render_404
      end
    rescue e : Errno
      raise e unless {Errno::EPIPE, Errno::ECONNRESET}.includes?(e.errno)
    end

    # the webroot for the server
    get "/" { |env| env.redirect "/index.html" }

    public_folder config.webroot
    add_handler Authentication.middleware
    if (env = ENV["KEMAL_ENV"]?) && (env == "test")
      # kemal-spec only works like this
      Kemal.run
    else
      # http://kemalcr.com/cookbook/reuse_port/
      Kemal.run do |conf|
        if server = conf.server
          server.bind_tcp("0.0.0.0", Flix.config.port.to_i, reuse_port: config.processes > 1)
        else
          raise "got nil server! look at config class"
        end
      end
    end
  end
end
