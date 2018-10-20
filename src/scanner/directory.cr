require "./metadata"

module Flix
  module Scanner
    class MediaDirectory < FileMetadata
      @children_hash : Hash(String, FileMetadata)?
      @json_cache : String?

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
              Flix.logger.debug "adding child #{child.name} to @children_hash for #{name}"
              @children_hash.not_nil![child.hash] = child
            end
          end
        end
        @children_hash
      end

      def <<(child : FileMetadata?)
        if @children.nil?
          @children = Array(FileMetadata).new
        end
        @children.not_nil! << child
        if @children_hash.nil?
          @children_hash = Hash(String, FileMetadata).new
        end
        @children_hash.not_nil![child.hash] = child
      end

      def each_child
        unless children.nil?
          @children_hash.not_nil!.each { |k, v| yield k, v }
        end
      end

      def to_json
        return @json_cache unless @json_cache.nil?
        buf = String::Builder.new
        builder = JSON::Builder.new(buf)
        builder.start_document unless builder.state == JSON::Builder::DocumentStartState
        to_json(builder)
        builder.end_document unless already_started?
        @json_cache = buf.to_s
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          Flix.logger.debug "Adding title #{name.inspect} and thumbail #{thumbnail.inspect} to json"
          builder.field "title", name
          unless thumbnail.nil?
            builder.field "thumbnail", thumbnail.hash
          end
          children_count = 0
          each_child do |hash, child|
            if child.is_a? MediaDirectory
              # debugger
              builder.field child.hash do
                child.as(MediaDirectory).to_json(builder)
              end
            else
              Flix.logger.debug "Added child #{child.name} to directory #{name}'s json"
              builder.field hash, child.name
              children_count += 1
            end
          end
          if children_count == 0
            Flix.logger.warn "got no children from #{self.inspect}"
          end
        end
      end

      def is_dir?
        true
      end
    end
  end
end
