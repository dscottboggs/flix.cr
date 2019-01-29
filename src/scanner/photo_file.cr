# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "yaml"

module Flix::Scanner
  class PhotoFile < FileMetadata
    class ConfigData < FileMetadata::ConfigData
      def initialize(from photo : PhotoFile)
        @title = photo.name
      end
    end

    def config_data
      ConfigData.new from: self
    end
  end
end
