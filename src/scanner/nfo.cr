require "json"
require "./*"

module Flix::Scanner
  struct NFO
    include JSON::Serializable

    @[JSON::Field(key: "MimeType", emit_null: true)]
    property mime_type : String?

    @[JSON::Field(key: "FileName")]
    property file_name : String

    @[JSON::Field(key: "ParentDir")]
    property parent_dir : String

    def initialize(@mime_type : String?, @file_name, @parent_dir); end
  end

  abstract class FileMetadata
    def nfo
      NFO.new textual_mime_type,
        _filename,
        if rent = parent
          Scanner.hash rent.path
        else
          ""
        end
    end
  end

  class Directory < FileMetadata
    def nfo
      NFO.new "inode/directory", _filename, ""
    end
  end
end
