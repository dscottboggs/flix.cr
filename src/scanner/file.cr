# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "digest"
require "../errors/unknown_filetype"

module Flix
  module Scanner
    extend self

    # To be honest, this is a bit of a hack. Ideally, one would use libmagic
    # to perform this kind of hack, but since there aren't bindings to libmagic
    # yet, and magic comes with a machine-parsable command-line interface,
    # we instead use the `file` command to compare the mime-type at the given
    # filepath to determine the filetype.
    #
    # ```
    # | Mime-type found | return value |
    # ___________________________________
    # | video/mp4       | :mp4         |
    # | video/webm      | :webm        |
    # | image/jpeg      | :jpeg        |
    # | image/png       | :png         |
    # ```
    #
    # Since this is using CLI parsing, it invokes a shell and performs
    # comparisons on strings, rather than a simple file-read as libmagic
    # bindings would offer.
    #
    # OPTIMIZE THIS
    #
    def mime_type(path : String)
      if (mime_text = `file --brief --mime "#{command_escape path}"`).starts_with? "video/mp4"
        return :mp4
      elsif mime_text.starts_with? "video/webm"
        return :webm
      elsif mime_text.starts_with? "image/jpeg"
        return :jpeg
      elsif mime_text.starts_with? "image/png"
        return :png
      elsif (mime_text.starts_with?("application/octet-stream") &&
            path.ends_with?(".mp4"))
        # TODO: double check this is a good idea
        return :mp4
      else
        raise Flix::Scanner::UnknownFiletype.new path, mime_text
      end
    end

    # Returns true if .mime_type would return a type that represents a video
    # file, I.E. :mp4 or :webm
    def is_video?(filepath : String)
      {:mp4, :webm}.includes?(Scanner.mime_type(filepath))
    end

    # Returns true if mime_type would return a type that represents an image.
    def is_image?(filepath : String)
      {:png, :jpeg}.includes?(Scanner.mime_type(filepath))
    end

    def hash(filepath : String)
      digest = Digest::MD5.digest(filepath).to_slice
      hash_size = digest.size/2
      hash_value = Bytes.new(hash_size)
      hash_size.times do |i|
        hash_value[i] = digest[i] ^ digest[i + hash_size]
      end
      Base64.urlsafe_encode hash_value
    end

    def command_escape(filepath : String)
      String.build do |s|
        filepath.each_char do |char|
          if char == '"'
            s << '\'
          end
          s << char
        end
      end
    end
  end
end
