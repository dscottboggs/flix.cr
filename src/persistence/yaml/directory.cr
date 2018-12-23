# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

require "./metadata"
require "yaml"

class Flix::Scanner::MediaDirectory < Flix::Scanner::FileMetadata
  # struct Serializer
  #   include YAML::Serializable
  # end

  def initialize(ctx : YAML::ParseContext, node)
    read = super ctx, node
    @children = read.content
    @thumbnail = read.thumbnail
  end
end
