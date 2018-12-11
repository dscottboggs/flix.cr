# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "json"
require "./mime_type"

module Flix
  module Scanner
    abstract class FileMetadata
      @@all_videos = Hash(String, VideoFile).new
      @@all_photos = Hash(String, PhotoFile).new
      property path : String
      @name : String?
      setter name : String
      @hash : String?
      @stat : File::Info?
      property thumbnail : PhotoFile?
      property parent : MediaDirectory? = nil

      def initialize(@path : String,
                     @stat : File::Info? = nil,
                     @thumbnail : PhotoFile? = nil)
        @name = FileMetadata.get_title_from @path
      end

      def self.from_file_path?(filepath : String) : self | Nil
        info = File.info? filepath
        self.new path: filepath, stat: info unless info.nil?
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

      def filename
        File.basename path
      end

      # Just the section at the end of the filename after the final '.', if that
      # dot is less than 5 characters from the end of the filename. Nillable!
      def extension : String?
        dot_loc = path.rindex '.'
        if dot_loc && dot_loc >= (path.size - 5)
          path[dot_loc..-1]
        end
      end

      # The filename without its `#extension` component. If the `#extension` is
      # `nil`, this is the whole filename.
      def without_extension
        dot_loc = filename.rindex '.'
        if dot_loc && dot_loc >= (filename.size - 5)
          filename[0..dot_loc]
        else
          filename
        end
      end

      def to_s
        %{<"#{name}"@#{path}$#{hash}>}
      end

      # Uses some heuristics to parse a human-readable title from some common
      # filename conventions.
      #
      # If there are any spaces in the filename this step is skipped and the
      # filename is used verbatim.
      def self.get_title_from(filepath : String) : String
        underscores, dots = 0_u32, 0_u32
        filename = File.basename filepath
        index = filename.rindex '.'
        if index && filename.size - index <= 5
          filename = filename[0..index - 1]
        end
        filename.each_char do |char|
          return filename if char == ' '
          dots += 1 if char == '.'
          underscores += 1 if char == '_'
        end
        if underscores > 0 || dots > 0
          return filename
            .gsub('_', ' ')
            .gsub(/\s+/, " ")
            .strip if underscores > dots
          return filename
            .gsub('.', ' ')
            .gsub(/\s+/, " ")
            .strip
        end
        filename = filename.gsub '-', " -"
        subs = Hash(Char, Char | String).new
        ('A'..'Z').each { |l| subs[l] = " " + l }

        filename.gsub(subs).strip
      end

      def self.from_file_path?(filepath : String, stat : Crystal::System::FileInfo? = nil) : FileMetadata?
        # TODO: This null check should probably be done differently because it
        # technically could raise an exception but it works for now. I don't
        # want to wrap the whole method in a conditional, that gets messy.
        possibly_nil_info = stat || File.info? filepath
        return if possibly_nil_info.nil?
        info = possibly_nil_info.not_nil!
        if info.file? && MimeType.of(filepath).try &.is_a_video?
          # we got a video file!
          Flix.logger.debug "\
            got video at #{filepath} in \
            Flix::Scanner::FileMetadata.from_file_path?"
          return VideoFile.new path: filepath, stat: info
        end
        unless info.directory?
          Flix.logger.warn "got unrecognized file at #{filepath}"
          return
        end
        thumb : PhotoFile? = nil
        videos_in_this_dir : UInt64 = 0
        photos_in_this_dir : UInt64 = 0
        out_dir = MediaDirectory.new path: filepath, stat: info
        Flix.logger.debug "\
          got directory at #{filepath} in \
          Flix::Scanner::FileMetadata.from_file_path?"

        Dir.open filepath, &.each_child do |file|
          fullpath = File.join(filepath, file)
          info = File.info fullpath

          if MimeType.of(fullpath).try &.is_a_photo?
            photos_in_this_dir += 1
            FileMetadata << PhotoFile.new path: fullpath, stat: info
            next
          end

          new_file = from_file_path? fullpath

          case new_file
          when nil then next
          when .is_dir?
            Flix.logger.debug "\
              found child dir at #{fullpath} in directory #{filepath} in \
              Flix::Scanner::FileMetadata.from_file_path?"
            new_file.parent = out_dir
            out_dir << new_file.as MediaDirectory
          else
            if MimeType.of(fullpath).try &.is_a_video?
              Flix.logger.debug "\
                found child video at #{fullpath} in directory #{filepath} in \
                Flix::Scanner::FileMetadata.from_file_path?"
              videos_in_this_dir += 1
              new_file.parent = out_dir
              out_dir << new_file.as VideoFile
              FileMetadata << new_file.as VideoFile
            end
          end
        end

        # returns the first video in out_dir's children if out_dir only has one child video.
        if videos_in_this_dir == 1 && out_dir.children && out_dir.children.not_nil!.size == 1
          Flix.logger.debug "\
            only found one child video at #{out_dir.children.not_nil!.first_value} in \
            directory #{filepath} in \
            Flix::Scanner::FileMetadata.from_file_path?; returning that video\
            instead of the directory at #{filepath}.\n"
          return out_dir.children.not_nil!.first_value
        end
        out_dir.thumbnail = thumb unless thumb.nil?
        Flix.logger.debug "Got final dir #{out_dir.inspect}."
        out_dir
      end

      {% for filetype in {:video, :photo} %}
      # add the {{filetype.id}} to the hash of all {{filetype.id}}s
      def self.<<({{filetype.id}} : {{filetype.id.capitalize}}File)
        @@all_{{filetype.id}}s[{{filetype.id}}.hash] = {{filetype.id}}
      end
      {% end %}

      def self.all_videos
        if @@all_videos.empty?
          Flix.logger.warn "empty list of videos"
        end
        # Flix.logger.debug "all_videos: #{@@all_videos.inspect}"
        @@all_videos
      end

      def self.all_photos
        if @@all_photos.empty?
          Flix.logger.warn "empty list of photos"
        end
        # Flix.logger.debug "all_photos: #{@@all_photos.inspect}"
        @@all_photos
      end

      # run this once all the photos and videos are found. It assigns any photo
      # with the same name (file basename formatted with `#get_title_from`) as a
      # video to be that video's thumbnail.
      def self.associate_thumbnails
        photo_names = Hash(String, PhotoFile).new
        @@all_photos.values.each { |img| photo_names[img.name] = img }
        @@all_videos.each do |hash, vid|
          photo = photo_names[vid.name]?
          Flix.logger.debug "Video name: #{vid.name}\nPhoto with that name? #{photo ? "yes" : "no"}"
          vid.thumbnail = photo if photo
          @@all_videos[hash] = vid
        end
        Flix.logger.debug "all_videos after association: #{@@all_videos}"
      end
    end
  end
end
