module Flix
  class Configuration
    property port
    property config_location
    property debug = true
    property webroot : String = ENV["flix_webroot"]? || File.join(
      File.dirname(Dir.current), "flix_webui"
    )
    setter dirs
    @logger : Logger?
    @initialized_dirs : Array(Scanner::MediaDirectory)

    def initialize(@config_location : String,
                   @port : UInt16,
                   @dirs = Array(String).new)
      if @dirs.empty?
        @dirs = default_dirs
      end
      # this must be the same as dirs=(), but @initialized_dirs needs to be
      # initialized directly from within the constructor. Watch for changes!
      @initialized_dirs = @dirs.map do |dir|
        Scanner::MediaDirectory.from_file_path? dir
      end.reject! &.nil?
    end

    def logger : Logger
      if @logger.nil?
        @logger = Logger.new STDOUT, level: debug ? Logger::DEBUG : Logger::WARN
      else
        @logger.not_nil!
      end
    end

    def dirs : Array(Scanner::MediaDirectory)
      @initialized_dirs
    end

    def dirs=(dirs : Array(String))
      @initialized_dirs = dirs.map do |dir|
        Scanner::MediaDirectory.from_file_path? dir
      end.reject! &.nil?
    end

    # The default directory of media to serve up.
    def default_dirs
      # TODO: make better
      [File.join(ENV["HOME"], "Videos", "Public")]
    end
  end
end
