# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "../../scanner/photo_file"
require "./metadata"

module Flix
  module Scanner
    class PhotoFile < FileMetadata
      struct Serializer
        property title : String
        property location : String

        def initialize(@title : String, @location : String); end
      end

      def initialize(@path : String,
                     @stat : File::Info? = nil)
        @thumbnail = nil
        super
      end

      def initialize(@path : String,
                     @name : String,
                     @stat : File::Info? = nil)
        @thumbnail = nil
        super
      end

      # copy values from a `Serializer` to `self`.
      def initialize(read : Serializer)
        @name = read.title
        @path = read.location
      end
    end
  end
end
