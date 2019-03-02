# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./subtitles/mapping"

module Flix
  module Scanner
    class VideoFile < FileMetadata
      property subtitles : SubtitleFile::Mapping do
        SubtitleFile::Mapping.new
      end

      # The metadata about a directory formatted to be stored in a YAML file.
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

      # The metadata about this directory formatted to be stored in a YAML file.
      property config_data do
        ConfigData.new from: self
      end

      # Merge data from a config file into the already stored or detected
      # metadata.
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

      # Store all the subtitles in the given directory in the subtitles mapping
      # in this class.
      def using_all_subtitles_in(dir : MediaDirectory)
        dir.each_subtitle do |_, subs|
          subtitles[subs.language] = subs
        end
        self
      end
    end
  end
end
