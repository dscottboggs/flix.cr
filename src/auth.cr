require "./auth/*"

module Flix::Authentication
  extend self

  @@users = AllUsers.new at: USERS_FILE

  def encrypt(password)
    Scrypt::Password.create(password, KEY_LENGTH, SALT_SIZE)
  end

  def auth_middleware
    auth_handler = Kemal::AuthToken.new
    auth_handler.sign_in do |name, password|
      if @@users[name]? == password
        User.new(name: name).to_h
      else
        {"error" => true}
      end
    end
    auth_handler.load_user do |jwt_payload|
      User.load? user_info: jwt_payload
    end
    auth_handler
  end

  def check_username_pw(user : User, password : String)
    @@users[user.name]? == password
  end

  def set_username_pw(user : User, password)
    @@users[user.name] = enrypt password
  end

  def user_exists?(named username)
    !!@@users[username]?
  end
end
