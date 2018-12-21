# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "logger"

module Flix
  class Configuration
    struct Defaults
      class_property webroot : String
      class_property config_location : String
      class_property media_dirs : Array(String)
      class_property sign_in_endpoint  : String
      class_property home_dir
      class_property port : UInt16
      @@webroot : String = ENV["flix_webroot"]? || File.join(File.dirname(Dir.current), "flix_webui", "build")
      @@config_location : String = ENV["flix_config"]? || File.join(config_home, "flix.cr")
      @@media_dirs : Array(String) = [File.join(@@home_dir, "Videos", "Public")]
      @@config_home : String? = nil
      def self.config_home : String
        if conf_home = ENV["XDG_CONFIG_HOME"]?
          # $XDG_CONFIG_HOME is set, use that as the config parent dir
          Dir.mkdir conf_home unless File.exists? conf_home
          return (@@config_home = conf_home).not_nil!
        end

        if (home = ENV["HOME"]?) && File.directory?(conf_home = File.join(home, ".config"))
          # $XDG_CONFIG_HOME is not set, but the standard place for it to be
          # exists, so use that.
          return (@@config_home = conf_home).not_nil!
        end

        if (user = ENV["USER"]?) && (home = "/home/#{user}") && (File.directory? home)
          # ~/.config doesn't exist, but we're going to make it and use it
          # anyway
          conf_home = File.join(home, ".config")
          Dir.mkdir conf_home unless File.directory? conf_home
          return (@@config_home = conf_home).not_nil!
        end

        if `uname` == "Darwin"
          # mac OS
          mac_conf_home = "/Users/#{ENV["USER"]}/.config"
          Dir.mkdir mac_conf_home unless File.exists? mac_conf_home
          return (@@config_home = mac_conf_home).not_nil!
        end
        raise "couldn't find default config directory, please set the $XDG_CONFIG_HOME environment variable"
      end
      @@home_dir : String = (
        if home = ENV["HOME"]?
          home
        elsif (user = ENV["USER"]?) && File.directory?(home1 = "/home/#{user}")
          home1.not_nil!
        elsif user && File.directory?(home2 = "/Users/#{user}")
          home2.not_nil!
        else
          STDERR.puts "couldn't find home folder, please set the $HOME environment variable."
          "" # intentionally breaks things later
        end
      )
      @@sign_in_endpoint : String = "/sign_in"
      @@port = 9999
    end

    property port : UInt16 = Defaults.port
    # The directory to place the config file in. The config file contains
    # mappings of titles to filepaths, so you can override the title
    # automatically generated from the filename. This location also contains the
    # user authentication tokens.
    property config_location : String = Defaults.config_location
    # If the "flix_debug" environment variable is set to any value, or this
    # property is set, extra logging information will be sent to stdout.
    property debug = !!ENV["flix_debug"]?
    # The absolute path of the web interface to use for this server instance.
    # The default is to check the "flix_webroot" environment variable, or to
    # fall back on the absolute path of the directory at
    # `$PWD/../flix_webui/build/`.
    property webroot : String = Defaults.webroot
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
    def processes=(other)
      @processes = other.to_i
    end

    property sign_in_endpoint : String = Defaults.sign_in_endpoint
    property allow_unauthorized : Bool = ENV["KEMAL_ENV"]? == "test"

    def processes : Int
      @processes ||= ENV["flix_processes"]?.try &.to_i || 1
    rescue e : ArgumentError
      @processes = 1
    end

    def initialize(@config_location : String = Defaults.config_location,
                   @dirs = Defaults.media_dirs)
      check_config_dir
      @processes = processes.to_i
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

    private macro scan_dirs
      @dirs.each do |dir|
        if (i_dir = Scanner::FileMetadata.from_file_path? dir) && i_dir.is_dir?
          @initialized_dirs << i_dir.as(Scanner::MediaDirectory)
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
