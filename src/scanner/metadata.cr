# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "json"
require "yaml"
require "./mime_type"

module Flix
  module Scanner
    # The interface that all directory and media files implement and default
    # methods on those files.
    abstract class FileMetadata
      class_property all_videos = Hash(String, VideoFile).new
      class_property all_photos = Hash(String, PhotoFile).new
      property path : String
      @name : String?
      setter name : String
      @hash : String?
      @stat : File::Info?
      property thumbnail : PhotoFile?
      property parent : MediaDirectory? = nil
      @mime_type : MimeType?

      def initialize(@path : String,
                     @stat : File::Info? = nil,
                     @thumbnail : PhotoFile? = nil)
        @name = FileMetadata.get_title_from @path
      end

      # returns false; Directory overloads this with true
      def is_dir?
        false
      end

      def name : String
        @name ||= FileMetadata.get_title_from path
      end

      # the hash of the filepath as generated by the Scanner
      def hash : String
        @hash ||= Scanner.hash @path
      end

      def quick_stat : File::Info
        if @stat.nil?
          @stat = stat
        else
          @stat
        end
      end

      def stat : File::Info
        @stat = File.info path
      end

      def _filename
        File.basename path
      end

      # Just the section at the end of the filename after the final '.', if that
      # dot is less than 5 characters from the end of the filename. Nillable!
      def self.extension(of_this filename) : String?
        dot_loc = path.rindex '.'
        if dot_loc && dot_loc >= (path.size - 5)
          path[dot_loc..-1]
        end
      end

      # The filename without its `#extension` component. If the `#extension` is
      # `nil`, this is the whole filename.
      def self.without_extension(filename)
        dot_loc = filename.rindex '.'
        if dot_loc && dot_loc >= (filename.size - 5)
          filename[0..dot_loc]
        else
          filename
        end
      end

      def extension
        extension of_this: _filename
      end

      def without_extension
        without_extension _filename
      end

      def to_s
        %{<"#{name}"@#{path}$#{hash}>}
      end

      def mime_type
        @mime_type ||= MimeType.of path
      end

      def mime_type!
        @mime_type ||= MimeType.of! path
      end

      # The mime type of the current file as a string
      def textual_mime_type
        if mt = mime_type
          mt.to_s
        end
      end

      # Uses some heuristics to parse a human-readable title from some common
      # filename conventions.
      #
      # If there are any spaces in the filename this step is skipped and the
      # filename is used verbatim.
      def self.get_title_from(filepath : String) : String
        underscores, dots = 0_u32, 0_u32
        filename = File.basename filepath
        # trim off the extension
        if filename.size - (index = filename.rindex('.') || 0) <= 5
          filename = filename[0..index - 1]
        end
        # count dots and underscores
        filename.each_char do |char|
          # also check for spaces, since we're already iterating over all of them
          return filename if char == ' '
          dots += 1 if char == '.'
          underscores += 1 if char == '_'
        end
        # replace underscores or dots, depending on which has more
        if underscores > 0 || dots > 0
          subchar = if underscores > dots
                      '_'
                    else
                      '.'
                    end
          return filename
            .gsub(/\\#{subchar}([a-zA-Z])/) { |ss, match| " " + match[0].upcase }
            .gsub(subchar, ' ')
            .gsub(/\s+/, " ")
            .strip
        end
        # no spaces, dots, or underscores, so that leaves us with CamelCase
        filename = filename.gsub '-', " -"
        subs = Hash(Char, Char | String).new
        ('A'..'Z').each { |l| subs[l] = " " + l }
        filename = filename.sub 0, filename[0].upcase

        filename.gsub(subs).strip
      end

      def self.from_file_path?(filepath : String, stat : Crystal::System::FileInfo? = nil) : FileMetadata?
        if info = File.info? filepath # skip everything if the file is not valid
          if info.file? && (mime_type = MimeType.of filepath)
            if mime_type.is_a_video?
              # we got a video file!
              return VideoFile.new path: filepath, stat: info
            elsif mime_type.is_a_photo?
              # we got a picture!
              return PhotoFile.new path: filepath, stat: info
            end
          end
          return unless info.directory?
          videos_in_this_dir : UInt64 = 0
          photos_in_this_dir : UInt64 = 0
          children_dir_count : UInt64 = 0
          out_dir = MediaDirectory.new path: filepath, stat: info

          # time to figure out what all the children files are in this directory
          Dir.open filepath, &.each_child do |file|
            fullpath = File.join(filepath, file)
            info = File.info fullpath

            if new_file = from_file_path? fullpath
              case new_file.mime_type
              when nil then nil
              when .is_a_dir?
                new_file.parent = out_dir
                out_dir << new_file.as MediaDirectory
                children_dir_count += 1
              when .is_a_photo?
                photos_in_this_dir += 1
                FileMetadata << new_file.as PhotoFile
              when .is_a_video?
                videos_in_this_dir += 1
                new_file.parent = out_dir
                out_dir << new_file.as VideoFile
                FileMetadata << new_file.as VideoFile
              end
            end
          end

          # returns the first video in out_dir's children if out_dir only has one child video.
          if videos_in_this_dir == 1 && (kids = out_dir.children) && kids.size == 1
            return kids.first_value
          end
          out_dir
        end
      end

      {% for filetype in {:video, :photo} %}
      # add the {{filetype.id}} to the hash of all {{filetype.id}}s
      def self.<<({{filetype.id}} : {{filetype.id.capitalize}}File)
        @@all_{{filetype.id}}s[{{filetype.id}}.hash] = {{filetype.id}}
      end
      {% end %}

      # run this once all the photos and videos are found. It assigns any photo
      # with the same name (file basename formatted with `#get_title_from`) as a
      # video to be that video's thumbnail.
      def self.associate_thumbnails
        photo_names = Hash(String, PhotoFile).new
        @@all_photos.values.each { |img| photo_names[img.name] = img }
        @@all_videos.each do |hash, vid|
          photo = photo_names[vid.name]?
          # Flix.logger.debug "Video name: #{vid.name}\nPhoto with that name? #{photo ? "yes" : "no"}"
          vid.thumbnail = photo if photo
          @@all_videos[hash] = vid
        end
        # p! @@all_videos.size
        # Flix.logger.debug "all_videos after association: #{@@all_videos}"
      end

      # ### <<<<     Configuration serialization section     >>>> #####

      # A convenience structure for converting to YAML.
      abstract class ConfigData
        include YAML::Serializable
        # The human-readable title of the associated file, which may be
        # overridden.
        property title : String

        # An assiciated thumbnail. Nil by default. Subclasses which are
        # able to associate thumbnails should override this.
        def thumbnail
          nil
        end

        # :nodoc:
        def content
          nil
        end

        def initialize(from config : FileMetadata)
          @title = config.name
        end
      end

      abstract def config_data

      def merge!(with config : ConfigData) : self
        raise <<-HERE unless same_path? as: config
        attempted to merge #{path} with #{other.path} which is a different
        location
        HERE
        name = config.title
        self
      end
    end
  end
end
