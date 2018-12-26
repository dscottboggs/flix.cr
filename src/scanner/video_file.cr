# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class VideoFile < FileMetadata
      alias Serialized = Hash(String, String)
      def serialize : Serialized
        {
          "title" => name,
          "thumbnail" => thumbnail || "none",
          "location" => path
        }
      end
      def self.deserialize(serialized data : Serialized)
        thumb = data["thumbnail"]
        thumb = nil if thumb == "none"
        new name: data["title"], path: data["location"], thumbnail: thumb
      end
      def merge!(with other : self) : self
        super
        thumbnail = other.thumbnail if other.thumbnail
        self
      end
      def merge(with other : self) : self
        raise <<-HERE unless same_path? as: other
        attempted to merge #{path} with #{other.path} which is a different
        location
        HERE
        new path: path, name: other.name, thumbnail: other.thumbnail || thumbnail
      end
    end
  end
end
