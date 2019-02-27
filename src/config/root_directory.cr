require "json"

class Flix::Configuration
  class RootDirectory
    property dirs = [] of Scanner::MediaDirectory

    delegate :<<, :first, :to_json, to: @dirs

    def map(&block : Scanner::MediaDirectory -> R) : Iterable(R) forall R
      @dirs.map { |dir| yield dir }
    end

    def each(&block : Scanner::MediaDirectory -> Void) : Void
      @dirs.each { |dir| yield dir }
    end

    def initialize(paths : Array(String))
      scan dirs: paths
    end

    {% if env("KEMAL_ENV") == "test" %}
    # When specs are run, they MUST be run with the $KEMAL_ENV environment
    # variable set to "test". So, lets take advantage of that to compile some
    # convenience methods for testing.

    def initialize(initialized @dirs : Array(Scanner::MediaDirectory))
    end
    {% else %}
    # For the `.from_json` method
    private def initialize(initialized @dirs : Array(Scanner::MediaDirectory));end
    {% end %}

    {% for filetype in [:subtitle, :photo, :video] %}
      # Dig through all child directories for a {{filetype.id}} file
      def []?(*, {{filetype.id}} id : String) : Scanner::{{filetype.capitalize.id}}File?
        each do |dir|
          if found = dir[{{filetype.id}}: id]?
            return found
          end
        end
      end

      # Dig through all child directories for a {{filetype.id}} file, raising
      # an IndexError if no file with the given id is found.
      def [](*, {{filetype.id}} id : String)
        self[{{filetype.id}}: id]? || raise IndexError.new "couldn't find {{filetype.id}} with id #{id.inspect}"
      end
    {% end %}

    def <<(dir path : String)
      scan dirs: [path]
    end

    private def scan(dirs paths : Array(String))
      paths.each do |dirpath|
        if (dir = Scanner::FileMetadata.from_file_path? dirpath) && dir.is_dir?
          @dirs << dir.as Scanner::MediaDirectory
        end
      end
    end
  end
end
