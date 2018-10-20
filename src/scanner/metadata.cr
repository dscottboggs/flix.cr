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
