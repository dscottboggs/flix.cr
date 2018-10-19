require "kemal"
require "./route_helpers"

module Flix
  extend self

  def serve_up
    get "/ping" do
      "pong"
    end

    get "/dmp" do
      config.dirs.to_json
    end

    get "/img/:id" { |env| serve_image env }
    get "/img" { |env| serve_image env }
    get "/vid/:id" { |env| serve_video env }
    get "/vid" { |env| serve_video env }

    get "/" { |env| env.redirect "/index.html" }

    public_folder config.webroot

    Kemal.config do |conf|
      conf.port = Flix.config.port.to_i
    end
    begin
      Kemal.run
    rescue e : Errno
      if e.errno == Errno::EADDRINUSE
        Flix.logger.error "port #{Kemal.config.port} is in use.\n"
      end
      raise e
    end
  end
end
