# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

require "option_parser"

module Flix
  extend self

  class Configuration
    # Help text values for each option
    module HelpText
      DIR = "\
        Set a media directory (can be specified multiple times)
        Default: #{Defaults.media_dirs.join}\n"
      PORT = "\
        set the port number on which the API should be accessible
        Default: #{Defaults.port}\n"
      CONFIG_LOCATION = "\
        set the config file location
        Default: #{Defaults.config_location}\n"
      WEBROOT = "\
        the location of the web app to serve
        Default: #{Defaults.webroot}\n"
      PROCESSES = "\
        the number of processes to use. UNSTABLE
        Default: 1\n"
      SIGN_IN_ENDPOINT = "\
        the resource path to request a new authentication token
        Default: #{Defaults.sign_in_endpoint}\n"
      DISABLE_AUTH = "\
        make this instance totally public with no authentication requests
        Default: false\n"
    end

    OPTIONS = {:port, :webroot, :processes, :sign_in_endpoint}

    # Create a new Configuration from command-line arguments
    def self.from_args(args)
      port = nil
      webroot = nil
      processes = nil
      sign_in_endpoint = nil
      config_location = nil
      dirs = [] of String
      disable_auth = nil

      OptionParser.parse args do |parser|
        parser.banner = %<"flix": a streaming video server\n>

        parser.on "-d DIR", "--dir=DIR", HelpText::DIR do |dir|
          dirs << dir
        end

        parser.on "-c LOCATION", "--config=LOCATION", HelpText::CONFIG_LOCATION do |loc|
          config_location = loc unless loc.empty?
        end

        parser.on "-p PORT", "--port=PORT", HelpText::PORT do |p_val|
          begin
            port = p_val.to_u16
          rescue e : ArgumentError
            Flix.logger.error "port number #{port.inspect} must be a valid integer between 1 and 65535"
            raise e
          end
        end

        parser.on "-r WEBROOT", "--webroot=WEBROOT", HelpText::WEBROOT do |wr|
          webroot = wr
        end

        parser.on "-P PROCS", "--processes=PROCS", HelpText::PROCESSES do |procs|
          processes = procs
        end

        parser.on "--sign-in-endpoint=PATH", HelpText::SIGN_IN_ENDPOINT do |path|
          sign_in_endpoint = path
        end

        parser.on "--no-auth", HelpText::DISABLE_AUTH do
          disable_auth = true
        end

        parser.on "-h", "--help", "Show this help message" do
          puts parser
          exit
        end

        parser.invalid_option do |flag|
          Flix.logger.error "ERROR: #{flag} is not a valid option."
          Flix.logger.error parser
          exit 64 # Usage exit code
        end
      end
      dirs = Defaults.media_dirs if dirs.empty?
      conf = new dirs: dirs.reject! &.empty?, config_location: (config_location || Defaults.config_location).not_nil!
      {% for opt in OPTIONS %}
      if not_nil_{{opt.id}} = {{opt.id}}
        conf.{{opt.id}} = not_nil_{{opt.id}}
      end
      {% end %}
      conf.allow_unauthorized if disable_auth == true
      raise "port cannot be 0" if port == 0
      conf
    end
  end
end
