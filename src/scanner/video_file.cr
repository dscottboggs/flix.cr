# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "yaml"

module Flix
  module Scanner
    class VideoFile < FileMetadata
      class ConfigData < FileMetadata::ConfigData
        property thumbnail : String?
        def initialize(from video : VideoFile)
          @title = video.name
          @thumbnail = video.thumbnail.try &.path
        end

        property thumbnail
      end

      def config_data
        ConfigData.new from: self
      end

      def merge!(with config : ConfigData) : self
        super
        if thumb = config.thumbnail
          thumbnail = thumb
        end
        self
      end
    end
  end
end
