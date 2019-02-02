# make private methods accessible.
class Flix::Authentication::Handler
  def test_sign_in(with context)
    sign_in with: context
  end

  def test_load_user(from context)
    load_user from: context
  end

  def _encode(data)
    encode data
  end

  def _decode(jwt)
    decode jwt
  end
end

describe Flix::Authentication::Handler do
  it "responds with a token on successful sign in" do
    users = Flix::Authentication::AllUsers.new({"test user" => Flix::Authentication.encrypt("test user's password")})
    handler = Flix::Authentication::Handler.new users: users
    IO.pipe do |reader, writer|
      context = HTTP::Server::Context.new(
        request: HTTP::Request.new(method: "GET",
          resource: "/sign_in",
          body: {
            "name"     => "test user",
            "password" => "test user's password",
          }.to_json),
        response: HTTP::Server::Response.new io: writer
      )
      spawn { context = handler.test_sign_in with: context }
      Fiber.yield
      context.response.status_code.should eq 200
      spawn { reader.gets.should_not be_nil }
      Fiber.yield
    end
  end
  it "responds with an access denied message on login failure" do
    users = Flix::Authentication::AllUsers.new({"test user" => Flix::Authentication.encrypt("test user's password")})
    handler = Flix::Authentication::Handler.new users: users
    IO.pipe do |reader, writer|
      context = HTTP::Server::Context.new(
        request: HTTP::Request.new("GET",
          "/sign_in",
          body: {
            "name"     => "test user",
            "password" => "not the test user's password",
          }.to_json),
        response: HTTP::Server::Response.new io: writer
      )
      spawn { handler.test_sign_in with: context }
      Fiber.yield
      context.response.status_code.should eq 403
      spawn { reader.gets.should eq "Unauthorized.\n" }
      Fiber.yield
    end
  end
  it "responds with an access denied message when there's no body" do
    users = Flix::Authentication::AllUsers.new({"test user" => Flix::Authentication.encrypt("test user's password")})
    handler = Flix::Authentication::Handler.new users: users
    IO.pipe do |reader, writer|
      context = HTTP::Server::Context.new(
        request: HTTP::Request.new("GET", "/sign_in"),
        response: HTTP::Server::Response.new io: writer
      )
      spawn { handler.test_sign_in with: context }
      Fiber.yield
      context.response.status_code.should eq 403
      spawn { reader.gets.should eq "Unauthorized.\n" }
      Fiber.yield
    end
  end
  it "responds with a \"Bad request.\" response when invalid JSON is received" do
    users = Flix::Authentication::AllUsers.new({"test user" => Flix::Authentication.encrypt("test user's password")})
    handler = Flix::Authentication::Handler.new users: users
    IO.pipe do |reader, writer|
      context = HTTP::Server::Context.new(
        request: HTTP::Request.new("GET",
          "/sign_in",
          body: {
            "unexpected key" => "some value",
          }.to_json),
        response: HTTP::Server::Response.new io: writer
      )
      spawn { handler.test_sign_in with: context }
      Fiber.yield
      context.response.status_code.should eq 400
      spawn reader.gets.should eq "Bad Request.\n"
      Fiber.yield
    end
  end
  it "loads the user" do
    users = Flix::Authentication::AllUsers.new({"test user" => Flix::Authentication.encrypt("test user's password")})
    handler = Flix::Authentication::Handler.new users: users
    response_body = IO::Memory.new
    context = HTTP::Server::Context.new(
      request: HTTP::Request.new("GET", "/any/endpoint"),
      response: HTTP::Server::Response.new io: response_body
    )
    context.request.headers["X-Token"] = handler._encode UserHash{"name" => "test user"}
    handler.test_load_user from: context
    context.current_user.should_not be_nil
    context.current_user.try(&.["name"]).should eq "test user"
  end
end
