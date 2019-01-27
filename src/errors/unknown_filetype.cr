# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

module Flix
  module Scanner
    class UnknownFiletype < Exception
      def initialize(filepath : String, mime : String)
        super "\
        unknown filetype for #{filepath}: #{`file --brief #{filepath}`.strip} \
        (mime type #{mime.strip})."
      end
    end
  end
end
