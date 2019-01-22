require "./auth/*"

# The authentication module handles storing users, hashing passwords, and
# authenticating users by comparing a recieved password to the existing hashed
# password. It uses the *scrypt* hashing algorithm.
module Flix::Authentication
  extend self

  @@users = AllUsers.new at: USERS_FILE

  # Create an Scrypt::Password for the given password text
  def encrypt(password)
    Scrypt::Password.create(password, KEY_LENGTH, SALT_SIZE)
  end

  # Check that the given user's password matches the stored hash.
  def check_username_pw(user : User, password : String)
    # Scrypt::Password overloads the == operator to determine a hash match.
    # A user which doesn't exist returns nil from []?, so that would not "=="
    # the password either.
    @@users[user.name]? == password
  end

  # Set the plaintext password for the given user.
  def set_username_pw(user : User, password : String)
    @@users[user.name] = encrypt password
  end
  # Set the already encrypted password for the given user
  def set_username_pw(user : User, password : Scrypt::Password)
    @@users[user.name] = password
  end

  def user_exists?(named username)
    !!@@users[username]?
  end
end
