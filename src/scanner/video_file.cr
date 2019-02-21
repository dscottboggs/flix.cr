# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class VideoFile < FileMetadata
      property subtitles : SubtitleFile?

      class ConfigData
        include YAML::Serializable
        property thumbnail : String?
        property title : String
        property subtitles : String?

        def initialize(from video : VideoFile)
          @title = video.name
          @thumbnail = video.thumbnail.try &.path
          @subtitles = video.subtitles.try &.path
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
        if subs = config.subtitles
          @subtitles = SubtitleFile.from_file_path?(subs).as SubtitleFile?
        end
        self
      end
    end
  end
end
