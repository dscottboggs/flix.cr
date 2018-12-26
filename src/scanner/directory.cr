# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"

module Flix
  module Scanner
    class MediaDirectory < FileMetadata
      alias ChildrenType = Array(Serialized | PhotoFile::Serialized | VideoFile::Serialized)
      alias Serialized = Hash(String, ChildType | String)
      @children_hash = Hash(String, FileMetadata).new
      @json_cache : String?

      delegate :size, to: @children_hash

      property :path, :thumbnail, :name

      def initialize(@path : String,
                     @children = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
        @name = FileMetadata.get_title_from @path
      end

      def initialize(@path : String,
                     @name : String,
                     @children = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
      end

      def children=(@children : Array(FileMetadata))
        @json_cache = nil
      end

      def children : Hash(String, FileMetadata)
        if @children_hash.values != @children
          @children.each do |child|
            @children_hash[child.hash] = child
          end
        end
        @children_hash
      end

      def <<(child : FileMetadata?)
        @children << child
        @json_cache = nil
        @children_hash[child.hash] = child
      end

      def each_child
        @children_hash.each { |k, v| yield k, v }
      end

      # The dump methods are for serializing for network communication. More
      # data is necessary to persist the state to disk, so #serialize and
      # self.deserialize should be used for those purposes.
      def dump : String
        @json_cache ||= begin
          buf = String::Builder.new
          builder = JSON::Builder.new(buf)
          builder.document do
            to_json(builder)
          end
          buf.to_s
        end
      end

      def dump(builder : JSON::Builder)
        builder.object do
          builder.field "title", name
          builder.field "thumbnail", thumbnail.hash unless thumbnail.nil?
          each_child do |hash, child|
            if child.is_dir?
              builder.field child.hash do
                child.as(MediaDirectory).to_json(builder)
              end
            else
              builder.field hash, child.name
            end
          end
          if size == 0
            # Flix.logger.warn "got no children from #{self.inspect}"
          end
        end
      end

      def is_dir?
        true
      end

      # a hash of the data needed to store this directory and recreate it.
      # this data can then be formatted for storage in various formats.
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
      # recreate a Directory from the state stored to disk.
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
      def merge!(with other : self) : self
        super
        thumbnail = other.thumbnail if other.thumbnail
        other.each_child do |key, child|
          self[key].merge! with: child if self[key]?
        end
        self
      end
      def merge(with other : self) : self
        raise <<-HERE unless same_path? as: other
        attempted to merge #{path} with directory #{other.path} which is a
        different location
        HERE
        output = new path: path, name: other.name, thumbnail: other.thumbnail || thumbnail
        other.each_child do |key, child|
          output.children[key] = merge self[key], with: child
        end
        output
      end
    end
  end
end
