# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

# JWT authorization middleware
class Flix::Authentication::Handler < Kemal::Handler

  # This struct is used to deserialize the received login information
  struct ReceivedUser
    include JSON::Serializable
    property name : String
    property password : String
  end

  # Used to encrypt all JWTs
  private property secret_key : String

  def initialize(@users : AllUsers, @secret_key = Random::Secure.base64(32), @algorithm = "HS256"); end

  # Load in the users from the given location (or the configured one, by
  # default).
  def initialize(@secret_key = Random::Secure.base64(32), @algorithm = "HS256", users_file = Flix.config.users_file)
    @users = AllUsers.new at: users_file
  end

  # Kemal::Handlers must implement call, this is how Kemal communicates with
  # the middleware.
  def call(context)
    return sign_in with: context if context.request.path === Flix.config.sign_in_endpoint
    load_user from: context
    call_next context
  rescue e : JWT::VerificationError
    Flix.logger.debug e.message
    context.response.status_code = 403
    context.response.content_type = "text/plain"
    context.response.puts "Bad JWT. Reauthenticate."
    # do not call the next context
  end

  # Authenticate a user from JSON-encoded credentials in the request body,
  # and return to the user a JWT if they succeed the authentication challenge.
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

  # Check the request headers and URL query parameters for a decryptable JWT,
  # and use User.load to set the User as the current_user attribute of the
  # context which will be recieved by other middleware.
  private def load_user(from context : HTTP::Server::Context) : Void
    if token = (context.request.headers["X-Token"]? || context.params.query["auth"]?)
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
