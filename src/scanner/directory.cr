require "../conf"
require "./metadata"

module Scanner
  class MediaDirectory < FileMetadata
    @children_hash : Hash(String, FileMetadata)?

    def initialize(@path : String,
                   @children : Array(FileMetadata)? = nil,
                   @thumbnail : PhotoFile? = nil)
      @name = FileMetadata.get_title_from @path
    end

    def children=(@children : Array(FileMetadata))
    end

    def children : Hash(String, FileMetadata)?
      if @children_hash.nil? || @children_hash.not_nil!.values != @children
        if @children_hash.nil?
          @children_hash = Hash(String, FileMetadata).new
        end
        unless (c = @children).nil?
          c.each do |child|
            LOGGER.debug "adding child #{child.name} to @children_hash for #{name}"
            @children_hash.not_nil![child.hash] = child
          end
        end
      end
      @children_hash
    end

    def self.from_file_path?(filepath : String) : MediaDirectory?
      children = Array(FileMetadata).new
      thumb : PhotoFile? = nil
      out_dir = MediaDirectory.new path: filepath
      Dir.open(filepath) do |dir|
        dir.each_child do |file|
          fullpath = File.join(filepath, file)
          info = File.info fullpath
          if info.directory?
            child_dir = self.from_file_path? fullpath
            children << child_dir unless child_dir.nil?
          else
            filetype = Scanner.mime_type fullpath
            if {:mp4, :webm}.includes? filetype
              vid = VideoFile.from_file_path? fullpath
              next if vid.nil?
              vid.parent = out_dir
              children << vid
              FileMetadata << vid
            elsif {:png, :jpeg}.includes? filetype
              thumb = PhotoFile.from_file_path? fullpath
              next if thumb.nil?
              thumb.not_nil!.parent = out_dir
              FileMetadata << thumb
            end
          end
        end
      end
      out_dir.children = children
      out_dir.thumbnail = thumb unless thumb.nil?
      out_dir
    end
  end
end
