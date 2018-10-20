# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "json"

module Flix
  module Scanner
    abstract class FileMetadata
      @@all_videos = Hash(String, VideoFile).new
      @@all_photos = Hash(String, PhotoFile).new
      property path : String
      @name : String?
      @hash : String?

      def initialize(@path : String,
                     @stat : File::Info? = nil,
                     @thumbnail : PhotoFile? = nil)
        @name = FileMetadata.get_title_from @path
      end

      def is_dir?
        false
      end

      def name=(@name : String); end

      def name : String
        if @name.nil?
          @name = FileMetadata.get_title_from path
        else
          @name.not_nil!
        end
      end

      def hash : String
        if @hash.nil?
          @hash = Scanner.hash @path
        else
          @hash.not_nil!
        end
      end

      @stat : File::Info?
      property thumbnail : PhotoFile?
      property parent : MediaDirectory? = nil

      def self.from_file_path?(filepath : String) : self | Nil
        info = File.info? filepath
        self.new path: filepath, stat: info unless info.nil?
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

      def extension
        dot_loc = path.rindex '.'
        if dot_loc && dot_loc >= (path.size - 5)
          path[dot_loc..-1]
        end
      end

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

      def self.from_file_path?(filepath : String) : FileMetadata?
        possibly_nil_info = File.info? filepath
        return if possibly_nil_info.nil?
        info = possibly_nil_info.not_nil!
        if info.file? && Scanner.is_video? filepath
          # we got a video file!
          Flix.logger.debug "\
            got video at #{filepath} in \
            Flix::Scanner::FileMetadata.from_file_path?"
          return VideoFile.new path: filepath
        end
        unless info.directory?
          Flix.logger.warn "got unrecognized file at #{filepath}"
          return
        end
        thumb : PhotoFile? = nil
        videos_in_this_dir : UInt64 = 0
        photos_in_this_dir : UInt64 = 0
        maybe_nil_out_dir = MediaDirectory.new path: filepath
        return if maybe_nil_out_dir.nil?
        out_dir = maybe_nil_out_dir.not_nil!
        Flix.logger.debug "\
          got directory at #{filepath} in \
          Flix::Scanner::FileMetadata.from_file_path?"
        Dir.open(filepath) do |dir|
          dir.each_child do |file|
            fullpath = File.join(filepath, file)
            info = File.info fullpath
            if info.directory?
              Flix.logger.debug "\
                found child dir at #{fullpath} in directory #{filepath} in \
                Flix::Scanner::FileMetadata.from_file_path?"
              child_dir = self.from_file_path? fullpath
              out_dir << child_dir unless child_dir.nil?
            else
              filetype = Scanner.mime_type fullpath
              if {:mp4, :webm}.includes? filetype
                vid = VideoFile.new path: fullpath
                next if vid.nil?
                Flix.logger.debug "\
                  found child video at #{fullpath} in directory #{filepath} in \
                  Flix::Scanner::FileMetadata.from_file_path?"
                videos_in_this_dir += 1
                vid.parent = out_dir
                out_dir << vid
                FileMetadata << vid
              elsif {:png, :jpeg}.includes? filetype
                thumb = PhotoFile.new path: fullpath
                next if thumb.nil?
                Flix.logger.debug "\
                  found child photo at #{fullpath} in directory #{filepath} in \
                  Flix::Scanner::FileMetadata.from_file_path?"
                photos_in_this_dir += 1
                thumb.not_nil!.parent = out_dir
                FileMetadata << thumb
              end
            end
          end
        end
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

      def self.<<(video : VideoFile)
        @@all_videos[video.hash] = video
      end

      def self.<<(photo : PhotoFile)
        @@all_photos[photo.hash] = photo
      end

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
      # with the same name (file basename formatted with #get_title_from) as a
      # video to be that video's thumbnail.
      def self.associate_thumbnails
        photo_names = Hash(String, PhotoFile).new
        @@all_photos.values.each { |img| photo_names[img.name] = img }
        @@all_videos.each do |hash, vid|
          Flix.logger.debug "Video name: #{vid.name}\nPhoto with that name? #{photo_names[vid.name]?.nil? ? "no" : "yes"}"
          vid.thumbnail = photo_names[vid.name]?
          @@all_videos[hash] = vid
        end
        Flix.logger.debug "all_videos after association: #{p! @@all_videos}"
      end
    end
  end
end
