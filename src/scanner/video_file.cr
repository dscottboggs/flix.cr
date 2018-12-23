# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"

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

      def initialize(@path : String,
                     @stat : File::Info? = nil,
                     @thumbnail : PhotoFile? = nil)
        super
      end

      def initialize(@path : String,
                     @name : String,
                     @stat : File::Info? = nil,
                     @thumbnail : PhotoFile? = nil)
        super
      end

      # copy values from a `Serializer` to `self`.
      def initialize(read : Serializer)
        @name = read.title
        @path = read.location
        @thumbnail = read.thumbnail
      end
    end
  end
end
