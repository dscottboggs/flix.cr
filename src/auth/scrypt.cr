# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

# Reopens Scrypt::Password to allow for JSON serialization for persistence
require "scrypt"

class Scrypt::Password
  def initialize(pull : JSON::PullParser)
    @parts = (@raw_hash = pull.read_string).split "$"
  end

  def to_json(builder)
    builder.string @raw_hash
  end
end
