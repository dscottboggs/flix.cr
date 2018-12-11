require "./handler"

class Flix::DumpHandler < Flix::Handler
  only ["/dmp"]
  include Flix

  def call(env)
    skip_other_routes
    env.response.print config.dirs.to_json
  end
end
