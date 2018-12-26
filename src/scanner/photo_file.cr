# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class PhotoFile < FileMetadata
      alias Serialized = Hash(String, String)
      def serialize : Serialized
        {
          "title" => name,
          "location" => path
        }
      end
      def self.deserialize(serialized data : Serialized)
        new name: data["title"], path: data["location"]
      end
      def merge(with other : self) : self
        raise <<-HERE unless same_path? as: other
        attempted to merge #{path} with #{other.path} which is a different
        location
        HERE
        new name: other.name, path: path
      end
    end
  end
end
