# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class VideoFile < FileMetadata
      struct Serializer
        property title : String
        property location : String
        property thumbnail : PhotoFile?
        def initialize(data : VideoFile)
          @title = data.name
          @location = data.path
          @thumbnail = data.thumbnail
        end
      end
      def initialize(read : Serializer)
        deserialize read
      end
      # copy values from a `Serializer` to `self`.
      private macro deserialize(read)
        %read = ({{read.id}})
        @name = %read.title
        @path = %read.location
        @thumbnail = %read.thumbnail
      end
    end
  end
end
