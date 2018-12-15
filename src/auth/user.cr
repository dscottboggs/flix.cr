class Flix::Authentication::User
  property name : String

  def initialize(@name); end

  def self.load(user_info : Hash(String, JSON::Any)) : UserHash
    if (name_any = user_info["name"]?) && (name = name_any.as_s?) && !name.empty?
      User.new(name).to_h
    else
      puts %(got user_info["name"]? #=> #{user_info["name"]?.inspect})
      UserHash{"error" => true}
    end
  end

  def to_h
    UserHash{"name" => @name}
  end

  def is_authenticated_by?(password)
    Authentication.check_username_pw self, password
  end

  def set_password(to new_pw)
    Authentication.set_username_pw user: self, password: new_pw
  end

  def exists?
    Authentication.user_exists? named: @name
  end
end
