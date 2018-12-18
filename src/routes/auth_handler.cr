struct ReceivedUser
  include JSON::Serializable
  property name : String
  property password : String
end

# JWT authorization middleware
class Flix::Authentication::Handler < Kemal::Handler
  private property secret_key : String

  def initialize(@users : AllUsers, @secret_key = Random::Secure.base64(32), @algorithm = "HS256"); end

  def initialize(@secret_key = Random::Secure.base64(32), @algorithm = "HS256", users_file = Flix.config.users_file)
    @users = AllUsers.new at: users_file
  end

  def call(context)
    return sign_in with: context if context.request.path === Flix.config.sign_in_endpoint
    load_user from: context
    call_next context
  end

  private def sign_in(with context : HTTP::Server::Context) : HTTP::Server::Context
    if (body = context.request.body) && (user_info = ReceivedUser.from_json body)
      if (stored_pw = @users[user_info.name]?) && stored_pw == user_info.password
        json_output = {token: encode(HTTP::Server::Context::UserHash{"name" => user_info.name})}.to_json
        context.response.print json_output
        return context
      end
    end
    context.response.status_code = 403
    context.response.content_type = "text/plain"
    context.response.puts "Unauthorized."
    context
  rescue e : JSON::ParseException
    Flix.logger.debug e
    context.response.status_code = 400
    context.response.content_type = "text/plain"
    context.response.puts "Bad request."
    context
  end

  private def load_user(from context : HTTP::Server::Context) : Void
    if token = context.request.headers["X-Token"]?
      payload, header = decode jwt: token
      context.current_user = User.load user_info: payload
    end
  end

  private def encode(data : HTTP::Server::Context::UserHash)
    JWT.encode payload: data, key: @secret_key, algorithm: @algorithm
  end

  private def decode(jwt)
    JWT.decode token: jwt, key: @secret_key, algorithm: @algorithm
  end
end
