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

      def self.from_file_path?(path : String?, stat = nil)
        if info = stat || File.info? path
          if MimeType.of(path).try &.is_a_photo?
            new path, info
          end
        end
      end

      def clone
        _clone_ = self.class.new @path, @stat, @thumbnail
        _clone_.name = @name
        _clone_
      end

      def config_data
        ConfigData.new from: self
      end

      def merge!(with config : ConfigData) : self
        super
        if thumb = config.thumbnail
          @thumbnail = PhotoFile.from_file_path?(thumb).as PhotoFile?
        end
        self
      end
    end
  end
end
