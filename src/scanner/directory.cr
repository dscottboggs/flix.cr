# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "./metadata"
require "./subtitles/languages"

module Flix
  module Scanner
    # A directory which contains valid media files.
    class MediaDirectory < FileMetadata
      getter children_directories = [] of self

      def children_directories=(other : Array(self))
        @children_directories = other
      end

      @json_cache : String? = nil
      delegate :size, to: @children_videos

      {% for t in [:video, :subtitle, :photo] %}

      getter children_{{t.id}}s = [] of {{t.id.capitalize}}File

      def children_{{t.id}}s=(other : Array({{t.id.capitalize}}File))
        @children_{{t.id}}s = other
      end

      def []?(*, {{t.id}} id : String) : {{t.capitalize.id}}File?
        if found = @children_{{t.id}}s.find { |child| child.hash == id }
          return found
        end
        each_child_directory do |_, dir|
          if found = dir[{{t.id}}: id]
            return found
          end
        end
      end

      def [](*, {{t.id}} id : String) : {{t.capitalize.id}}File
        self[{{t.id}}: id]? || raise IndexError.new "ID #{id} not found in the {{t.id}}s"
      end


      # iterate over all the child files/directories. Each iteration, the block
      # recieves a pair of the string-hash by which the child is referenced, and
      # the child value itself.
      def each_{{t.id}}(&action : (String, {{t.id.capitalize}}File) -> Void) : Void
        @children_{{t.id}}s.each do |child|
          yield child.hash, child
        end
      end

      def first_{{t.id}}
        @children_{{t.id}}s.first
      end

      def last_{{t.id}}
        @children_{{t.id}}s.last
      end

      def find_{{t.id}}
        @children_{{t.id}}s.find { |child| yield child }
      end

      {% end %}

      # Cycles through each child file in the directory of any type, including
      # subdirectories. The order in which they are yielded is not guaranteed
      # to remain consistent.
      {% begin %}
      def each_child(&action : (String, FileMetadata) -> Void) : Void
        {% for ft in [:subtitle, :video, :photo] %}
        each_{{ft.id}}       { |id, child| yield id, child }    {% end %}
        each_child_directory { |id, child| yield id, child }
      end
      {% end %}

      # A directory is *directly* indexable by ID, for ANY type. There should
      # never be a collision between IDs, but in case there is, the files are
      # checked in this order: videos, photos, subtitles, directories. The
      # search is recursive. If no file is found in this dir or any subdirectory
      # matching the given ID, the response is `nil`
      def []?(id : String)
        self[video: id]? || self[photo: id]? || self[subtitle: id]? || self[dir: id]?
      end

      # A directory is *directly* indexable by ID, for ANY type. There should
      # never be a collision between IDs, but in case there is, the files are
      # checked in this order: videos, photos, subtitles, directories. The
      # search is recursive. If no file is found in this dir or any subdirectory
      # matching the given ID, an IndexError is raised.
      def [](id : String)
        self[id]? || raise IndexError.new "No file was found with the ID of #{id.inspect} in #{path.inspect}"
      end

      def []?(*, dir id : String) : self?
        if found = @children_directories.find { |child| child.hash == id }
          return found
        end
        each_child_directory do |_, dir|
          if found = dir[dir: id]?
            return found
          end
        end
      end

      def [](*, dir id : String)
        self[dir: id]? || raise IndexError.new "ID #{id} not found in the {{t.id}}s"
      end

      def each_child_directory(&action : (String, self) -> Void) : Void
        @children_directories.each do |child|
          yield child.hash, child
        end
      end

      def initialize(@path : String,
                     @videos = Array(FileMetadata).new,
                     @thumbnail : PhotoFile? = nil,
                     @stat : Crystal::System::FileInfo? = nil)
        @name = get_title_from @path
      end

      def clone
        _clone_ = self.class.new @path, @videos.clone, @thumbnail, @stat
        _clone_.name = @name
        _clone_
      end

      def children=(children : Array(FileMetadata))
        @json_cache = @config_data = nil
        @children_videos = children.select(&.is_a_video?).map &.as VideoFile
        @children_subtitles = children.select(&.is_a_subtitle?).map &.as SubtitleFile
        @children_photos = children.select(&.is_a_photo?).map &.as PhotoFile
        @children_directories = children.select(&.is_a_dir?).map &.as self
      end

      # Store a new child file/directory
      def <<(child : FileMetadata?)
        @json_cache = @config_data = nil
        child.parent = self
        case child
        when .is_a? VideoFile
          @json_cache = nil
          @children_videos << child.as VideoFile
        when .is_a? SubtitleFile
          @json_cache = nil
          @children_subtitles << child.as SubtitleFile
        when .is_a? PhotoFile
          @json_cache = nil
          @children_photos << child.as PhotoFile
        when .is_a? self
          @json_cache = nil
          @children_directories << child.as self
        end
      end

      # encode the directory into JSON for the /dmp endpoint. This is recursively
      # called on all child FileMetadata objects.
      def to_json : String
        @json_cache ||= begin
          String.build do |buf|
            JSON.build buf, indent: 2 do |json|
              to_json builder: json
            end
          end
        end
      end

      # :ditto:
      def to_json(builder : JSON::Builder) : Void
        builder.object do
          builder.field "title", name
          builder.field "thumbnail", thumbnail.hash unless thumbnail.nil?
          each_video do |hash, child|
            builder.field name: hash, value: child.name
          end
          each_child_directory do |hash, dir|
            builder.field name: hash do
              dir.as(MediaDirectory).to_json(builder)
            end
          end
        end
      end

      # returns true
      def is_dir?
        true
      end

      # Checks to see if the directory has only subtitles. **DOES NOT** set the
      # `#only_subtitles?` property, for that you should call
      # `#which_has_only_subtitles!`
      def has_only_subtitles?
        @children_subtitles.size > 0 &&
          @children_videos.empty? &&
          @children_photos.empty? &&
          @children_directories.empty?
      end

      def which_has_only_subtitles! : SubtitlesOnlyDirectory
        SubtitlesOnlyDirectory.new copy_of: self
      end

      def only_subtitles?
        false
      end

      @[AlwaysInline]
      def subtitles_child_dirs
        @children_directories.select &.only_subtitles?
      end

      def associate_thumbnails!
        each_video do |id, video|
          if photo = children_photos.find { |photo| photo.name == video.name }
            video.thumbnail = photo
          end
        end
        each_child_directory do |id, dir|
          dir.associate_thumbnails! unless dir.only_subtitles?
        end
      end

      def associate_subtitles!
        Flix.logger.debug "\
          associating subtitles for dir #{name.inspect}. Have subtitles \
          :\n#{children_subtitles.map { |subs| "#{subs.name.inspect} -- #{subs.path.inspect}\n" }}\n\
          for videos #{children_videos.map { |vid| "#{vid.name.inspect} -- #{vid.path.inspect}" }}\n"
        each_video do |id, video|
          children_subtitles.select { |subs| subs.name == video.name }.each do |subs|
            video.subtitles[Languages.from_language_code subs.language_code] = subs
          end
          if subs = children_subtitles.find { |subs| subs.name == video.name }
            video.subtitles[subs.language] = subs
          elsif (cdir = subtitles_child_dirs.find { |dir| dir.name == video.name }) &&
                (sd = cdir.which_has_only_subtitles! if cdir.has_only_subtitles?) &&
                (subs_dir = sd)
            subs_dir.associate_with this: video
          end
        end
        each_child_directory do |id, dir|
          dir.associate_subtitles! unless dir.only_subtitles?
        end
      end

      # ### <<<<     Configuration serialization section     >>>> #####

      class ConfigData
        include YAML::Serializable
        property title : String
        property thumbnail : String?
        # getter content : Iterator({String, FileMetadata::ConfigData})
        getter content : Hash(String, FileMetadata::ConfigData)

        def initialize(from dir : MediaDirectory)
          @title = dir.name
          @thumbnail = dir.thumbnail.try &.path
          @content = dir.children_videos
            .map { |vid|
              {vid.hash, vid.config_data.as FileMetadata::ConfigData}
            }
            .to_h
            .merge dir.children_directories
            .map { |d|
              {d.hash, d.config_data.as FileMetadata::ConfigData}
            }
            .to_h
        end
      end

      property config_data do
        ConfigData.new from: self
      end

      def merge!(with config : ConfigData) : self
        super
        if new_thumb = config.thumbnail
          thumbnail = PhotoFile.from_file_path? new_thumb
        end
        config.content.each do |id, metadata|
          if child = self[id]?
            child.merge! metadata
          else
            Flix.logger.error "couldn't merge metadata for file with id #{id} -- not found."
          end
        end
        self
      end
    end
  end
end
