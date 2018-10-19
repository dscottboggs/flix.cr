require "option_parser"

module Flix
  class Configuration
    property dirs
    property port
    property config_location
    property debug = true
    @logger : Logger?

    def logger : Logger
      if @logger.nil?
        @logger = Logger.new STDOUT, level: debug ? Logger::DEBUG : Logger::WARN
      else
        @logger.not_nil!
      end
    end

    def initialize(@config_location : String,
                   @port : UInt16,
                   @dirs = Array(String).new)
      if @dirs.empty?
        @dirs = default_dirs
      end
    end

    # Create a new Configuration from command-line arguments
    def self.parse_args
      dir_help = "Set a media directory (can be specified multiple times)"
      port_help = "set the port number on which the API should be accessible"
      dirs = Array(String).new
      config_location = ENV["flix_config"]? || File.join(ENV["HOME"], ".config", "flix")
      # TODO: revise default ^^
      port = (ENV["flix_port"]? || 80).to_u16
      OptionParser.parse! do |parser|
        parser.banner = %<"flix": a streaming video server>
        parser.on "-d", "--dir", dir_help do |dir|
          dirs << dir
        end
        parser.on "-c", "--config", "set the config file location" do |loc|
          config_location = loc
        end
        parser.on "-p", "--port", port_help do |p_val|
          port = p_val.to_u16
        end
        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts parser
          exit 64 # Usage exit code
        end
      end
      self.new dirs: dirs, config_location: config_location, port: port
    end

    # The default directory of media to serve up.
    def default_dirs
      # TODO: make better
      [File.join(ENV["HOME"], "Videos", "Public")]
    end
  end
end
