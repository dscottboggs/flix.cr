class Flix::Authentication::User
  include Authentication
  property name : String

  def initialize(@name); end

  def self.load?(user_info : UserHash)
    if (name = user_info["name"]?) && !name.empty?
      User.new(name).to_h
    end
  end

  def to_h
    {"name" => @name}
  end

  def is_authenticated_by?(password)
    check_username_pw self, password
  end

  def set_password(to new_pw)
    set_username_pw user: self, password: new_pw
  end

  def exists?
    user_exists? named: @name
  end
end
