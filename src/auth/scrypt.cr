require "scrypt"

class Scrypt::Password
  def initialize(pull : JSON::PullParser)
    @parts = (@raw_hash = pull.read_string).split "$"
  end

  def to_json(builder)
    builder.string @raw_hash
  end
end
