require "json"

module Scanner
  abstract class FileMetadata
    @@all_videos = Hash(String, VideoFile).new
    @@all_photos = Hash(String, PhotoFile).new
    property path : String
    @name : String?

    def name=(@name : String); end

    def name : String
      if @name.nil?
        @name = self.get_title_from path
      else
        @name
      end
    end

    @stat : File::Info?
    property thumbnail : PhotoFile?
    property parent : MediaDirectory? = nil

    def initialize(@path : String, @stat : File::Info? = nil)
      @name = self.get_title_from @path
    end

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

    def self.get_title_from(filepath : String)
      underscores, dots = 0_u32, 0_u32
      index = filepath.rindex '.'
      if index && filepath.size - index <= 5
        filepath = filepath[0..index - 1]
      end
      filepath.each_char do |char|
        return filepath if char == ' '
        dots += 1 if char == '.'
        underscores += 1 if char == '_'
      end
      if underscores > 0 || dots > 0
        return filepath
          .gsub('_', ' ')
          .gsub(/\s+/, " ")
          .strip if underscores > dots
        return filepath
          .gsub('.', ' ')
          .gsub(/\s+/, " ")
          .strip
      end
      filepath = filepath.gsub '-', " -"
      subs = Hash(Char, Char | String).new
      ('A'..'Z').each { |l| subs[l] = " " + l }

      filepath.gsub(subs).strip
    end
  end
end
