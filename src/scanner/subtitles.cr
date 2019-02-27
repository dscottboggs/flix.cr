# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "subtitles"
require "./mime_type"
require "../routes"
require "./metadata"
require "./subtitles/*"

module Flix::Scanner
  # A file which contains subtitle data.
  #
  # There's a touch of extra complexity here to deal with cases where the
  # subtitles are in a format incompatible with the client.
  class SubtitleFile < FileMetadata
    # :nodoc:
    # not actually used
    class ConfigData
      include YAML::Serializable
      property title : String

      def initialize(from file : FileMetadata)
        @title = file.name
      end

      def thumbnail
        nil
      end
    end

    setter mime_type : Scanner::MimeType?
    property content : IO?
    property language : Languages do
      Languages.from_language_code(language_code found_in: path)
    end

    # Override default initializer and @name property to account for the
    # extra extension to indicate the language

    property name do
      get_title_from without_language_code(path), strip_extension: false
    end

    def initialize(@path : String,
                   @stat : File::Info? = nil,
                   @thumbnail : PhotoFile? = nil,
                   @parent : MediaDirectory? = nil)
      @name = get_title_from without_language_code(@path), strip_extension: false
    end

    # Send the subtitles represented by this object to the given context. In the
    # case of a filetype which is already readable by the client (i.e.
    # substation format), this means simply sending the file. In any other case,
    # this method converts the contents and stores the converted version in
    # `@content`. If this process fails, the block is yielded to.
    # ```
    # if subs = config.dirs[subtitle: context.params[:id]]?
    #   subs.send to: context do
    #     page_not_found
    #   end
    # end
    # ```
    def send(to context : HTTP::Server::Context, &on_not_found)
      if buf = content
        # A cached conversion has already been placed in the buffer `@content`.
        context.send data: buf, mime_type: mime_type.to_s
        return
      end
      if (mt = mime_type) && mt.is_a_subtitle? && mt.is_substation?
        # There is a subtitle file at `#path`, and it's already in the right
        # format for the client. Just send the file as-is
        send_file context, path: path, mime_type: mime_type.to_s
        return
      end
      if (mt = mime_type) && mt.is_a_subtitle?
        # It's a subtitle file, but in a format other than Substation. Convert
        # to the appropriate format and cache the results
        if captions = Subtitles.parse filepath: path
          @content = content = Subtitles::SSA.new(captions).content
          context.response.content_type = (@mime_type = MimeType::SubStationSubtitles).to_s
          IO.copy src: content, dst: context.response
          return
        end
      end
      yield
    end

    def self.mime_type(of captions : Subtitles::Format) : Scanner::MimeType?
      mime_type of: captions.class
    end

    def self.mime_type(of _class : Subtitles::Format.class) : Scanner::MimeType?
      if {Subtitles::ASS, Subtitles::SSA}.includes? _class
        Scanner::MimeType::SubStationSubtitles
      elsif _class == Subtitles::SRT
        Scanner::MimeType::SubRipSubtitles
      elsif _class == Subtitles::JSON
        Scanner::MimeType::JSONSubtitles
      end
    end

    def clone
      the_clone = self.class.new @path, @stat
      the_clone.content = content
      the_clone.mime_type = mime_type
      the_clone
    end

    # :nodoc:
    # not actually used
    def config_data
      SubtitleFile::ConfigData.new self
    end
  end
end

# crystal with generics
# Rust with GC
# Go, Objective-C maybe? -- compiled, C-like with GC
#
# Dynamic languages which compile to an Abstract Syntax Tree which is
# then compiled, rather than bytecode to be run in a VM.
