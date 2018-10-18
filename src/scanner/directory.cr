require "../conf"
require "./metadata"

module Scanner
  class MediaDirectory < FileMetadata
    @children_hash : Hash(String, FileMetadata)?

    def initialize(@path : String,
                   @children : Array(FileMetadata)? = nil,
                   @thumbnail : PhotoFile? = nil)
      @name = self.get_title_from @path
    end

    setter children : Array(FileMetadata)

    def children : Hash(String, FileMetadata)
      if @children_hash.nil? || @children_hash.values != @children
        @children.each do |child|
          LOGGER.debug "adding child #{child.name} to @children_hash for #{name}"
          @children_hash[md5_hash_of child.path] = child
        end
      end
      @children_hash
    end

    def self.from_file_path?(filepath : String) : MediaDirectory?
      children : Array(FileMetadata)
      thumb : PhotoFile
      out_dir = MediaDirectory.new path: filepath, thumbnail: thumbnail
      Dir.open(filepath) do |dir|
        dir.each_child do |file|
          info = file.info
          if info.directory?
            child_dir = self.from_file_path? file.path
            children << child_dir unless child_dir.nil?
          else
            filetype = Scanner.mime_type file.path
            if {:mp4, :webm}.includes? filetype
              vid = VideoFile.from_file_path? file.path
              next if vid.nil?
              vid.parent = out_dir
              children << vid
              FileMetadata.all_videos << vid
            elsif {:png, :jpeg}.includes? filetype
              thumb = PhotoFile.from_file_path? file.path
              next if thumb.nil?
              thumb.parent = out_dir
              FileMetadata.all_photos << thumb
            end
          end
        end
      end
      out_dir.children = children
      out_dir
    end
  end
end
