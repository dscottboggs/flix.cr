# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "../../scanner/*"

abstract class Flix::Scanner::FileMetadata
  struct Serializer
    include YAML::Serializable
    include YAML::Serializable::Strict
  end
  def to_yaml(io : IO) : Void
    Serializer.new(self).to_yaml(io)
  end

  def initialize(ctx : YAML::ParseContext, nodes)
    read = Serializer.new ctx, nodes
    @path = read.location
    @name = read.content
    read
  end
  def self.from_yaml(io : IO) : self
    new Serializer.from_yaml io
  end
end
