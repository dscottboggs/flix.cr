require "yaml"
require "../scanner/metadata"
module Flix::Scanner
  # REOPENED
  abstract class FileMetadata
    abstract def serialize : self::Serialized
    abstract def self.deserialize( self::Serialize ) : self
  end
  # REOPENED
  class Directory < FileMetadata
    # hash of string to string or hash of string recursively ad infinitum
    alias ChildrenType = Array(Serialized | PhotoFile::Serialized | VideoFile::Serialized)
    alias Serialized = Hash(String, ChildType | String)
    def serialize : Serialized
      data = {
        "title" => name,
        "thumbnail" => thumbnail || "none",
        "location" => path
        "content" => ChildrenType.new
      }
      each_child do |child|
        data["content"] << child.serialize
      end
    end
    def self.deserialize(serialized data : Serialized) : self
      this = new name: data["title"], path: data["location"]
      if content = data["content"]?
        data["content"].each do |child|
          if child_content = child["content"]? # directory
            this.children << self.deserialize child
          elsif child["thumbnail"]? # video file
            this.children << VideoFile.deserialize child
          else
            this.children << PhotoFile.deserialize child
          end
        end
      end
      this
    end
  end
  # REOPENED
  class VideoFile < FileMetadata
    alias Serialized = Hash(String, String)
    def serialize : Serialized
      {
        "title" => name,
        "thumbnail" => thumbnail || "none",
        "location" => path
      }
    end
    def self.deserialize(serialized data : Serialized)
      new name: data["title"], path: data["location"]
    end
  end
  # REOPENED
  class PhotoFile < FileMetadata
    alias Serialized = Hash(String, String)
    def serialize : Serialized
      {
        "title" => name,
        "location" => path
      }
    end
    def self.deserialize(serialized data : Serialized)
      new name: data["title"], path: data["location"]
    end
  end
end
