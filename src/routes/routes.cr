require "kemal"

module Flix
  extend self
  def serve_up
    get "/ping" do
      "pong"
    end

    get "/dmp" do
      config.dirs.to_json
    end

    get "/img/:id" do |env|
      id = env.params.url["id"]
      photo = Scanner::FileMetadata.all_photos[id]?
      if photo.nil?
        video = Scanner::FileMetadata.all_videos[id]?
        if video.nil?
          render_404
          next
        else
          photo = video.thumbnail
        end
      end
      if photo.nil?
        render_404
      else
        send_file env, photo.not_nil!.path
      end
    end

    get "/vid/:id" do |env|
      video = Scanner::FileMetadata.all_videos[env.params.url["id"]]?
      if video.nil?
        render_404
      else
        send_file env, video.not_nil!.path
      end
    end

    get "/" { |env| env.redirect "/index.html" }

    public_folder config.webroot

    Kemal.config do |conf|
      conf.port = Flix.config.port.to_i
    end
    begin
      Kemal.run
    rescue e : Errno
      if e.errno == Errno::EADDRINUSE
        Flix.config.logger.error "port #{Kemal.config.port} is in use.\n"
      end
      raise e
    end
  end
end
