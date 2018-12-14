require "./handler"

class Flix::DumpHandler < Flix::Handler
  only ["/dmp"]

  def call(env)
    skip_other_routes
    env.response.print Flix.config.dirs.to_json
  end
end
