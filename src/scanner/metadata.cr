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

      def extension
        dot_loc = path.rindex '.'
        if dot_loc && dot_loc >= (path.size - 5)
          path[dot_loc..-1]
        end
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

      def self.<<(video : VideoFile)
        @@all_videos[video.hash] = video
      end

      def self.<<(photo : PhotoFile)
        @@all_photos[photo.hash] = photo
      end

      def all_videos
        @@all_videos
      end

      def all_photos
        @@all_photos
      end
    end
  end
end
