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
    serve_up config.processes - 1
    do_serve_up
  end

  # spawn `procs` number of forked servers.
  private def serve_up(procs : Int)
    Flix::MetadataConfig.synchronize!
    procs.times do
      fork do
        do_serve_up
      rescue e
        STDERR.puts "Fork died!! Excpetion was: #{e.message}\nRespawning..."
        serve_up 1
      end
    end
  end

  private def do_serve_up
    add_handler Authentication::Handler.new
    error 404 { "404 not found.\r\n" }
    error 403 { "Forbidden.\r\n" }
    get("/ping") { "pong" }
    # output a representation of the file structure
    get "/dmp" do |ctx|
      next unless Flix.config.allow_unauthorized || ctx.user_found?
      Flix.config.dirs.to_json.tap { |json| pp! json }
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

    get "/syn" do |ctx|
      Flix.config.reload!
      "OK."
    end

    put "/vid/name/:id", &update_video_title
    put "/vid/name", &update_video_title

    # the webroot for the server
    get("/", &.redirect "/index.html")

    public_folder config.webroot
    Kemal.config.env = "production" # unless Flix.config.debug
    if ((env = ENV["KEMAL_ENV"]?) && (env == "test"))
      # kemal-spec only works like this
      Kemal.run
    else
      # http://kemalcr.com/cookbook/reuse_port/
      Kemal.run do |conf|
        if server = conf.server
          if config.use_ssl?
            ssl = Kemal::SSL.new
            ssl.cert_file = config.cert_file.not_nil!
            ssl.key_file = config.key_file.not_nil!
            conf.ssl = ssl.context
            server.bind_tls(
              host: "0.0.0.0",
              port: config.port.to_i,
              context: conf.ssl.not_nil!,
              reuse_port: config.processes > 1)
          else
            server.bind_tcp("0.0.0.0", config.port.to_i, reuse_port: config.processes > 1)
          end
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
      return unless Flix.config.allow_unauthorized || context.user_found?
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      if video = Flix.config.all_videos[id]?
        video.nfo.to_json
      elsif photo = Flix.config.all_photos[id]?
        photo.nfo.to_json
      else
        page_not_found
      end
      nil
    end
  end

  # this method returns the Proc which gets called when the /img endpoint is
  # reached.
  def serve_img : HTTP::Server::Context -> Void
    # return a proc literal from a method to use on more than one route because DRY
    ->(context : HTTP::Server::Context) do
      return unless Flix.config.allow_unauthorized || context.user_found?
      Flix.logger.debug context.current_user
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      # try grabbing it as a thumbnail for a video first.
      Flix.logger.debug "got photo with ID #{id}"
      if (video = Flix.config.all_videos[id]?) &&
         (photo = video.thumbnail) &&
         (File.exists? photo.path)
        Flix.logger.debug "sending photo #{photo.path} of type #{photo.mime_type}"
        send_file context, path: photo.path, mime_type: photo.mime_type.to_s
      elsif (photo = Flix.config.all_photos[id]?) &&
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
      return unless Flix.config.allow_unauthorized || context.user_found?
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      Flix.logger.debug "got video with ID #{id}"
      if video = Flix.config.all_videos.tap { |vids| p! vids.keys, id }[id]?
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

  def update_video_title : HTTP::Server::Context -> Void
    ->(context : HTTP::Server::Context) do
      return unless Flix.config.allow_unauthorized || context.user_found?
      id = context.params.url["id"]? || context.params.query["id"]?
      if id.nil?
        page_not_found
        return
      end
      if video = Flix.config.all_videos[id]?
        if body = context.request.body
          video.name = body.gets_to_end
        end
        Flix::MetadataConfig.write_current_state
        context.response << "OK."
      else
        page_not_found
      end
      nil
    end
  end

  # Set the status code and render an appropriate 404 Not Found.
  macro page_not_found
    context.response.status_code = 404
    render_404
  end
end
