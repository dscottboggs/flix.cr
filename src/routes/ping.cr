require "./handler"
class Flix::PingHandler < Flix::Handler
  only ["/ping"]

  def call(env)
    skip_other_routes
    env.response.print "pong"
  end
end
