# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  module Scanner
    class VideoFile < FileMetadata
      property subtitles : Hash(Languages, SubtitleFile) do
        {} of Languages => SubtitleFile
      end

      class ConfigData
        include YAML::Serializable
        property thumbnail : String?
        property title : String
        property subtitles : Hash(String, String)?

        def initialize(from video : VideoFile)
          @title = video.name
          @thumbnail = video.thumbnail.try &.path
          @subtitles = video.subtitles.map do |lang, sub|
            {lang.language_code, sub.path}
          end.to_h unless video.subtitles.empty?
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
          subs.each do |lc, fp|
            subtitles[Languages.from_language_code lc] = SubtitleFile.from_file_path?(fp).as SubtitleFile
          end
        end
        self
      end
    end
  end
end
