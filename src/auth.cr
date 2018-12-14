require "./auth/*"

module Flix::Authentication
  extend self

  @@users = AllUsers.new at: USERS_FILE

  def encrypt(password)
    Scrypt::Password.create(password, KEY_LENGTH, SALT_SIZE)
  end

  def middleware
    auth_handler = Kemal::AuthToken.new
    auth_handler.sign_in do |email, password|
      output = UserHash.new
      if @@users[email]? == password
        output["name"] = email
      else
        output["error"] = true
      end
      output
    end
    auth_handler.load_user do |jwt_payload|
      User.load user_info: jwt_payload
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
