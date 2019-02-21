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
    # serve an image
    get "/img", &serve_img
    get "/img/:id", &serve_img
    # serve a video
    get "/vid", &serve_video
    get "/vid/:id", &serve_video
    # serve metadata
    get "/nfo", &metadata
    get "/nfo/:id", &metadata
    # Serve subtitles
    get "/ass", &subtitles
    get "/ass/:id", &subtitles

    # the webroot for the server
    get "/" { |context| context.redirect "/index.html" }

    public_folder Flix.config.webroot
    Kemal.config.env = "production" # unless Flix.config.debug
    if ((env = ENV["KEMAL_ENV"]?) && (env == "test"))
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

  # this method returns the Proc which gets called when the /nfo endpoint is
  # reached.
  def metadata
    ->(context : HTTP::Server::Context) do
      return unless user_found? in_headers_or_params_of: context
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
      return unless user_found? in_headers_or_params_of: context
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
      return unless user_found? in_headers_or_params_of: context
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

  def subtitles : HTTP::Server::Context -> Void
    ->(context : HTTP::Server::Context) do
      return unless user_found? in_headers_or_params_of: context
      id = context.params.url["id"]? || context.params.query["id"]? || return page_not_found
      Flix.logger.debug "got request for subtitles with ID #{id}"
      if subs = Scanner::FileMetadata.all_subtitles[id]? ||
                Scanner::FileMetadata.all_videos[id]?.try &.subtitles
        # some relevant subtitles were found either by ID or by their associated
        # video's ID
        subs.send(to: context) { page_not_found }
      else
        page_not_found
      end
    end
  end

  # Returns true if the user is found or if
  # Flix::Configuration.allow_unauthorized is set. Otherwise, sets the status
  # to *403 Forbidden* and returns false.
  def user_found?(in_headers_or_params_of context)
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
    nil
  end
end
