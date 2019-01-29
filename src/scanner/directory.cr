# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"

module Flix
  module Scanner
    # A directory which contains valid media files.
    class MediaDirectory < FileMetadata
      @children_hash = Hash(String, FileMetadata).new
      @json_cache : String?

      delegate :size, "[]", "[]?", "[]=", to: @children_hash

      def initialize(@path : String,
                     @children = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
        @name = FileMetadata.get_title_from @path
      end

      def children=(@children : Array(FileMetadata))
        @json_cache = nil
      end

      # Lazily translates the list of children into a hash-table, and returns
      # that hash-table.
      def children : Hash(String, FileMetadata)
        if @children_hash.values != @children
          @children.each do |child|
            @children_hash[child.hash] = child
          end
        end
        @children_hash
      end

      # Push a new child into the children of this directory
      def <<(child : FileMetadata?)
        @children << child
        @json_cache = nil
        @children_hash[child.hash] = child
      end

      # iterate over all the child files/directories. Each iteration, the block
      # recieves a pair of the string-hash by which the child is referenced, and
      # the child value itself.
      def each_child
        @children_hash.each { |k, v| yield k, v }
      end

      # encode the directory into JSON for the /dmp endpoint. This is recursively
      # called on all child FileMetadata objects.
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

      # :ditto:
      def to_json(builder : JSON::Builder)
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
        end
      end

      # returns true
      def is_dir?
        true
      end

      # ### <<<<     Configuration serialization section     >>>> #####

      class ConfigData < FileMetadata::ConfigData
        property title : String
        property thumbnail : String?
        # getter content : Iterator({String, FileMetadata::ConfigData})
        getter content : Hash(String, FileMetadata::ConfigData)

        def initialize(from dir : MediaDirectory)
          super
          @thumbnail = dir.thumbnail.try &.path
          @content = dir
            .children
            .map { |k, v| { k, v.config_data }}
            .to_h
            # .each
            # .map { |pair| {pair[0], pair[1].config_data} }
        end
      end

      def config_data
        ConfigData.new from: self
      end

      def merge!(with config : ConfigData) : self
        super
        if (new_thumb = config.thumbnail) && (thumb = @thumbnail)
          thumb.merge! new_thumb
        end
        config.contents.each do |pair|
          id, metadata = pair
          if child = self[id]?
            child.merge! metadata
          end
        end
        self
      end
    end
  end
end
