require "./auth/*"

module Flix::Authentication
  extend self

  @@signed_in_users = Hash(Token, String).new
  @@users = AllUsers.new at: USERS_FILE

  def encrypt(password)
    Scrypt::Password.create(password, KEY_LENGTH, SALT_SIZE)
  end

  def sign_in_with(name, password)
    jwt = UserHash.new
    if @@users[name]? == password
      token = Token.new
      @@signed_in_users[token] = name
      jwt["name"] = user.name
      jwt["token"] = token
    else
      jwt["error"] = true
    end
  end

  def get_signed_in_user(user_info)
    (token = user_info["token"]?) && @@signed_in_users[token]?
  end
end
