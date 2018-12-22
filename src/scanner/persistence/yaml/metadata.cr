# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

abstract class Flix::Scanner::FileMetadata
  def to_yaml(io : IO) : Void
    Serializer.new(self).to_yaml(io)
  end
  def self.from_yaml(io : IO) : self
    new Serializer.from_yaml io
  end
end
