require "json"
require "./*"

module Flix::Scanner
  # The JSON format that the /nfo endpoint returns
  struct NFO
    include JSON::Serializable

    @[JSON::Field(key: "MimeType", emit_null: true)]
    property mime_type : String?

    @[JSON::Field(key: "FileName")]
    property file_name : String

    @[JSON::Field(key: "ParentDir")]
    property parent_dir : String?

    @[JSON::Field(key: "Subtitles")]
    property subtitles : Hash(String, String)?

    def initialize(@mime_type : String?,
                   @file_name,
                   @parent_dir = nil,
                   @subtitles = {} of String => String)
    end
  end

  abstract class FileMetadata
    # returns a new Flix::Scanner::NFO filled out with the appropriate data for
    # the file this object represents.
    def nfo
      NFO.new textual_mime_type,
        _filename,
        if rent = parent
          Scanner.hash rent.path
        end
    end
  end

  class MediaDirectory < FileMetadata
    def nfo
      NFO.new "inode/directory", _filename
    end
  end

  class VideoFile < FileMetadata
    def nfo
      NFO.new textual_mime_type, _filename, parent.try(&.hash), unless subtitles.empty?
        subtitles.map { |lang, subs| {lang.language_code, subs.hash} }.to_h
      end
    end
  end
end
