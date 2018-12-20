# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "logger"

module Flix
  class Configuration
    property port
    # The directory to place the config file in. The config file contains
    # mappings of titles to filepaths, so you can override the title
    # automatically generated from the filename. This location also contains the
    # user authentication tokens.
    property config_location
    # If the "flix_debug" environment variable is set to any value, or this
    # property is set, extra logging information will be sent to stdout.
    property debug = !!ENV["flix_debug"]?
    # The absolute path of the web interface to use for this server instance.
    # The default is to check the "flix_webroot" environment variable, or to
    # fall back on the absolute path of the directory at
    # `$PWD/../flix_webui/build/`.
    property webroot : String = ENV["flix_webroot"]? || File.join(
      File.dirname(Dir.current), "flix_webui", "build"
    )
    @logger : Logger?
    @initialized_dirs : Array(Scanner::MediaDirectory)
    # Setting this higher than 1 sets Kemal to "reuse_port", and causes the given
    # number of forks before starting Kemal, effectively allowing multiprocess
    # serving.
    # Unfortunately, since this is a raw fork, there is currently no implemented
    # checks for crashes in other processes. If this is set to 4, for example,
    # and two of the processes encounter an exception, the application will chug
    # along with the two remaining processes as though nothing happened.
    #
    # As such, this feature is highly experimental, and disabled by default.
    setter processes : Int32?

    property sign_in_endpoint = "/sign_in"
    property allow_unauthorized : Bool = ENV["KEMAL_ENV"]? == "test"

    def processes : Int
      @processes ||= ENV["flix_processes"]?.try &.to_i || 1
    rescue e : ArgumentError
      @processes = 1
    end

    def initialize(@config_location : String,
                   @port : UInt16,
                   processes : String,
                   dirs = Array(String).new)
      check_config_dir
      @processes = processes.to_i
      @dirs = if dirs.empty?
                default_dirs
              else
                dirs
              end
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      scan_dirs
    end

    def initialize(@config_location : String,
                   @port : UInt16,
                   @processes = 1,
                   @dirs = Array(String).new)
      check_config_dir
      if @dirs.empty?
        @dirs = default_dirs
      end
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      scan_dirs
    end

    def users_file
      File.join @config_location, "users.auth"
    end

    def logger : Logger
      if @logger.nil?
        @logger = Logger.new STDOUT, level: Logger::DEBUG
      else
        @logger.not_nil!
      end
    end

    def dirs : Array(Scanner::MediaDirectory)
      @initialized_dirs
    end

    # An array of valid directories that contain valid media files. Currently
    # supported media types are defined by the Flix::Scanner::MimeType enum.
    def dirs=(@dirs : Array(String))
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      scan_dirs
    end

    # The default directory of media to serve up. Currently
    # `$HOME/Videos/Public`.
    # TODO: check multiple potential locations to find the one that exists.
    def default_dirs
      [File.join(ENV["HOME"], "Videos", "Public")]
    end

    private macro scan_dirs
      @dirs.each do |dir|
        if (i_dir = Scanner::FileMetadata.from_file_path? dir) &&
           i_dir.not_nil!.is_dir?
          @initialized_dirs << i_dir.not_nil!.as(Scanner::MediaDirectory)
        end
      end
      @initialized_dirs.reject! &.nil?
      Flix::Scanner::FileMetadata.associate_thumbnails
    end

    private macro check_config_dir
      if File.exists? @config_location
        raise "expected to find directory at #{@config_location}" unless File.directory? @config_location
      else
        Dir.mkdir_p @config_location
      end
    end
  end
end
