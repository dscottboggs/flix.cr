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

  # Begin serving the application
  def serve_up
    (config.processes - 1).times { fork { do_serve_up } }
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
      Flix.config.dirs.to_json
    end
    # serve an image
    get "/img", &serve_img
    get "/img/:id", &serve_img
    # serve a video
    get "/vid", &serve_video
    get "/vid/:id", &serve_video
    # serve metadata
    get "/nfo", &metadata
    get "/nfo/:id", &metadata

    # the webroot for the server
    get "/" { |context| context.redirect "/index.html" }

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

  # this method returns the Proc which gets called when the /nfo endpoint is
  # reached.
  def metadata
    ->(context : HTTP::Server::Context) do
      return unless user_found? context
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      if video = Scanner::FileMetadata.all_videos[id]?
        video.nfo.to_json
      elsif photo = Scanner::FileMetadata.all_photos[id]?
        photo.nfo.to_json
      else
        page_not_found
      end
    end
  end

  # this method returns the Proc which gets called when the /img endpoint is
  # reached.
  def serve_img : HTTP::Server::Context -> Void
    # return a proc literal from a method to use on more than one route because DRY
    ->(context : HTTP::Server::Context) do
      return unless user_found?(context)
      Flix.logger.debug context.current_user
      id = context.params.url["id"]? || context.params.query["id"]?
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
        send_file context, path: photo.path, mime_type: photo.mime_type.to_s
      elsif (photo = Scanner::FileMetadata.all_photos[id]?) &&
            (File.exists? photo.path)
        send_file context, path: photo.path, mime_type: Scanner::MimeType::Streamable.to_s
      else
        page_not_found
      end
      nil
    end
  end

  # this method returns the Proc which gets called when the /vid endpoint is
  # reached.
  def serve_video : HTTP::Server::Context -> Void
    # return a proc literal from a method to use on more than one route because DRY
    ->(context : HTTP::Server::Context) do
      return unless user_found?(context)
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      Flix.logger.debug "got video with ID #{id}"
      if video = Scanner::FileMetadata.all_videos[id]?
        Flix.logger.debug "rendering video #{video.path} of type #{video.mime_type}"
        send_file context, path: video.path, mime_type: Scanner::MimeType::Streamable.to_s
      else
        page_not_found
      end
      nil
  rescue e : Errno
    raise e unless {Errno::EPIPE, Errno::ECONNRESET}.includes? e.errno
    end
  end

  # Returns true if the user is found or if
  # Flix::Configuration.allow_unauthorized is set. Otherwise, sets the status
  # to *403 Forbidden* and returns false.
  def user_found?(context)
    if context.current_user.try(&.["name"]?) || Flix.config.allow_unauthorized
      true
    else
      context.response.status_code = 403
      false
    end
  end

  # Set the status code and render an appropriate 404 Not Found.
  macro page_not_found
    context.response.status_code = 404
    render_404
  end
end
