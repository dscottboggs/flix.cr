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

  def serve_up
    (config.processes - 1).times { fork { do_serve_up } }
    do_serve_up
  end

  private def do_serve_up
    get("/ping") { "pong" }
    Kemal.config.add_handler Authentication.middleware
    # output a representation of the file structure
    get("/dmp") { Flix.config.dirs.to_json }
    # serve an image
    get "/img", &serve_img
    get "/img/:id", &serve_img
    # serve a video
    get "/vid", &serve_video
    get "/vid/:id", &serve_video

    # the webroot for the server
    get "/" { |env| env.redirect "/index.html" }

    public_folder config.webroot
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

  def serve_img : HTTP::Server::Context -> Void
    # return a proc literal from a method to use on more than one route because DRY
    ->(env : HTTP::Server::Context) do
      id = env.params.url["id"]? || env.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      # try grabbing it as a thumbnail for a video first.
      Flix.logger.debug "got photo with ID #{id}"
      if (video = Scanner::FileMetadata.all_videos[id]?) &&
         (photo = video.thumbnail) &&
         (File.exists? photo.path)
        Flix.logger.debug "sending photo #{photo.path} of type #{photo.mime_type}"
        send_file env, path: photo.path, mime_type: photo.mime_type.to_s
      elsif (photo = Scanner::FileMetadata.all_photos[id]?) &&
            (File.exists? photo.path)
        send_file env, path: photo.path, mime_type: Scanner::MimeType::Streamable.to_s
      else
        page_not_found
      end
      nil
    end
  end

  def serve_video : HTTP::Server::Context -> Void
    # return a proc literal from a method to use on more than one route because DRY
    ->(env : HTTP::Server::Context) do
      id = env.params.url["id"]? || env.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      Flix.logger.debug "got video with ID #{id}"
      if video = Scanner::FileMetadata.all_videos[id]?
        Flix.logger.debug "rendering video #{video.path} of type #{video.mime_type}"
        send_file env, path: video.path, mime_type: Scanner::MimeType::Streamable.to_s
      else
        page_not_found
      end
      nil
  rescue e : Errno
    raise e unless {Errno::EPIPE, Errno::ECONNRESET}.includes?(e.errno)
    end
  end

  macro page_not_found
    env.response.status_code = 404
    render_404
  end
end
