# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"

module Flix
  module Scanner
    class MediaDirectory < FileMetadata
      @children_hash = Hash(String, FileMetadata).new
      @json_cache : String?

      delegate :size, to: @children_hash
      property path

      def initialize(@path : String,
                     @name : String,
                     @children = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
      end
      def initialize(@path : String,
                     @children = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
        @name = FileMetadata.get_title_from @path
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

      def to_json : String
        @json_cache ||= begin
          buf = String::Builder.new
          builder = JSON::Builder.new(buf)
          builder.document do
            to_json(builder)
          end
          buf.to_s
        end
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          # Flix.logger.debug "Adding title #{name.inspect} and thumbnail #{thumbnail.inspect} to json"
          builder.field "title", name
          builder.field "thumbnail", thumbnail.hash unless thumbnail.nil?
          each_child do |hash, child|
            if child.is_dir?
              # debugger
              builder.field child.hash do
                child.as(MediaDirectory).to_json(builder)
              end
            else
              # Flix.logger.debug "Added child #{child.name} to directory #{name}'s json"
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

      # for persistence serializers

      struct Serializer
        property title : String
        property thumbnail : PhotoFile?
        property content : Set(MediaDirectory)
        property location : String
        def initialize(dir : MediaDirectory)
          @title = dir.title
          @thumbnail = dir.thumbnail if dir.thumbnail
          @location = dir.path
          @content = dir.children
        end
      end

      def initialize(read : Serializer)
        deserialize read
      end

      # copy values from a `Serializer` to `self`.
      private macro deserialize(read)
        %read = ({{read.id}})
        @path = %read.location
        @children = %read.content
        @thumbnail = %read.thumbnail
        @name = %read.title
      end

    end
  end
end
