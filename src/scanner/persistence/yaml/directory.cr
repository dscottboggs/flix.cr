# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

require "yaml"
class Flix::Scanner::MediaDirectory
  struct Serializer
    include YAML::Serializable
  end
  def initialize(ctx : YAML::Context, node : YAML::Node::Node)
    deserialize Serializer.new ctx, node
  end
end
