require "./auth/*"

module Flix::Authentication
  extend self

  @@users = AllUsers.new at: USERS_FILE

  def encrypt(password)
    Scrypt::Password.create(password, KEY_LENGTH, SALT_SIZE)
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
