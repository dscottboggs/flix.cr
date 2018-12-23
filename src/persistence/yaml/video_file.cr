# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"
require "yaml"

class Flix::Scanner::VideoFile < Flix::Scanner::FileMetadata
  # struct Serializer
  #   include YAML::Serializable
  # end

  def initialize(ctx : YAML::ParseContext, nodes : YAML::Nodes::Node)
    read = super ctx, nodes
    @thumbnail = read.thumbnail
  end
end
