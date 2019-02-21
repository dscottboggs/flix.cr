# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "magic"

class HTTP::Server
  class Context
    alias UserHash = Hash(String, (String | Int32 | Nil | Bool))
    property current_user : UserHash?

    def send(data : IO, mime_type : String? = nil)
      mime_type ||= Magic.mime_type.of data
      if accepts? mime_type
        if accepts? encoding: "gzip"
          Gzip::Writer.open response do |zipper|
            IO.copy src: data, dst: zipper
          end
        else
          IO.copy src: data, dst: response
        end
      else
        STDERR.puts "tried to send file of type #{mime_type.inspect} in context which only accepts #{accepts}"
        response.status_code = 404
        response.puts "Not found."
      end
    end

    @[AlwaysInline]
    private def accepts : String?
      request.headers["Accept"]?
    end

    private def accepts?(mime_type : String) : Bool
      return true if accepts.try &.index mime_type
      false
    end

    @[AlwaysInline]
    private def accepts?(*, encoding : String)
      request.headers.includes_word? "Accept-Encoding", encoding
    end

  end
end
