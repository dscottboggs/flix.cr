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
