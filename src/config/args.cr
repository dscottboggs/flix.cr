require "option_parser"

module Flix
  extend self

  # Create a new Configuration from command-line arguments
  def parse_args
    dir_help = "Set a media directory (can be specified multiple times)"
    port_help = "set the port number on which the API should be accessible"
    dirs = Array(String).new
    config_location = ENV["flix_config"]? || File.join(ENV["HOME"], ".config", "flix")
    # TODO: revise default ^^
    port : UInt16 = (ENV["flix_port"]? || 80).to_u16
    OptionParser.parse! do |parser|
      parser.banner = %<"flix": a streaming video server>
      parser.on "-d DIR", "--dir=DIR", dir_help do |dir|
        dirs << dir
      end
      parser.on "-c LOCATION", "--config=LOCATION", "set the config file location" do |loc|
        config_location = loc unless loc.empty?
      end
      parser.on "-p PORT", "--port=PORT", port_help do |p_val|
        begin
          port = p_val.to_u16 unless p_val.empty?
        rescue e : ArgumentError
          Flix.logger.error "#{port.inspect} (type #{typeof(port)}) is not a valid UInt16"
          raise e
        end
      end
      parser.invalid_option do |flag|
        Flix.logger.error "ERROR: #{flag} is not a valid option."
        Flix.logger.error parser
        exit 64 # Usage exit code
      end
    end
    Configuration.new(
      dirs: dirs.reject! &.empty?,
      config_location: config_location,
      port: port
    )
  end
end
