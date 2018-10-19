require "digest"
require "../errors/unknown_filetype"

module Flix
  module Scanner
    extend self

    def mime_type(path : String)
      if (mime_text = `file --brief --mime #{path}`).starts_with? "video/mp4"
        return :mp4
      elsif mime_text.starts_with? "video/webm"
        return :webm
      elsif mime_text.starts_with? "image/jpeg"
        return :jpeg
      elsif mime_text.starts_with? "image/png"
        return :png
      elsif (mime_text.starts_with?("application/octet-stream") &&
            path.ends_with?(".mp4"))
        return :mp4
      else
        raise Flix::Scanner::UnknownFiletype.new path, mime_text
      end
    end

    def hash(filepath : String)
      digest = Digest::MD5.digest(filepath).to_slice
      hash_size = digest.size/2
      hash_value = Bytes.new(hash_size)
      hash_size.times do |i|
        hash_value[i] = digest[i] ^ digest[i+hash_size]
      end
      Base64.urlsafe_encode hash_value
    end
  end
end
