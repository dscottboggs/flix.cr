# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

# A single user and their authentication information.
class Flix::Authentication::User
  property name : String

  def initialize(@name); end

  # Load the user from the decrypted JWT or return an appropriate error value.
  def self.load(user_info : Hash(String, JSON::Any)) : UserHash
    if (name_any = user_info["name"]?) && (name = name_any.as_s?) && !name.empty?
      User.new(name).to_h
    else
      puts %(got user_info["name"]? #=> #{user_info["name"]?.inspect})
      UserHash{"error" => true}
    end
  end

  # returns a UserHash mapping the User's properties.
  def to_h
    UserHash{"name" => @name}
  end

  # returns true if the given password matches the known hash for this user.
  # See Authentication.check_username_pw.
  def is_authenticated_by?(password)
    Authentication.check_username_pw self, password
  end

  # set the password for this user.
  # See Authentication.set_username_pw.
  def set_password(to new_pw)
    Authentication.set_username_pw user: self, password: new_pw
  end

  # returns true if this user currently exists.
  # See Authentication.user_exists.
  def exists?
    Authentication.user_exists? named: @name
  end
end
