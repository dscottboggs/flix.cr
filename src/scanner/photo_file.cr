# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class PhotoFile < FileMetadata
      struct Serializer
        property title : String
        property location : String
        def initialize(@title : String, @location : String);end
      end
      # copy values from a `Serializer` to `self`.
      private macro deserialize(read)
        %read = ({{read.id}})
        @name = %read.title
        @path = %read.location
      end
      def initialize(read : Serializer)
        deserialize read
      end
    end
  end
end
