# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "kemal"
require "subtitles"
require "./mime_type"
require "../routes"
require "./metadata"

module Flix::Scanner
  class SubtitleFile < FileMetadata
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

    def send(to context : HTTP::Server::Context, &on_not_found)
      if buf = content
        # A cached conversion has already been placed in the buffer `@content`.
        context.send data: buf, mime_type: MimeType::SubRipSubtitles.to_s
        return
      elsif (mt = mime_type) && mt.is_a_subtitle? && mt.is_substation?
        # There is a subtitle file at `#path`, and it's already in the right
        # format for the client. Just send the file as-is
        send_file context, path: path, mime_type: mime_type.to_s
        return
      elsif (mt = mime_type) && mt.is_a_subtitle?
        # It's a subtitle file, but in a format other than Substation. Convert
        # to the appropriate format and cache the results
        if captions = Subtitles.parse filepath: path
          @content = content = Subtitles::SSA.new(captions).content
          context.response.content_type = MimeType::SubStationSubtitles.to_s
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
