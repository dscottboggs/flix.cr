# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "digest"
require "../errors/unknown_filetype"

module Flix
  module Scanner
    extend self

    def hash(filepath : String)
      digest = Digest::MD5.digest(filepath).to_slice
      hash_size = digest.size/2
      hash_value = Bytes.new(hash_size)
      hash_size.times do |i|
        hash_value[i] = digest[i] ^ digest[i + hash_size]
      end
      Base64.urlsafe_encode(hash_value).strip('=')
    end

    def command_escape(filepath : String)
      String.build do |s|
        filepath.each_char do |char|
          if char == '"'
            s << '\\'
          end
          s << char
        end
      end
    end
  end
end
