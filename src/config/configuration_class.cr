# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

require "logger"
require "./metadata_config_module"

module Flix
  class Configuration
    include MetadataConfiguration

    # The default values of each configuration options.
    struct Defaults
      class_property webroot : String
      class_property config_location : String
      class_property media_dirs : Array(String)
      class_property sign_in_endpoint = "/sign_in"
      class_property home_dir
      class_property port : UInt16 = 9999
      class_property debug = !!ENV["flix_debug"]?
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

      @@home_dir = (
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
      @@sign_in_endpoint = "/sign_in"
      @@port = 9999
    end

    property port : UInt16 = Defaults.port
    # The directory to place the config file in. The config file contains
    # mappings of titles to filepaths, so you can override the title
    # automatically generated from the filename. This location also contains the
    # user authentication tokens.
    getter config_location : String = Defaults.config_location

    def config_location=(location : String)
      conf_dir = File.dirname location
      Dir.mkdir_p conf_dir unless Dir.exists? conf_dir
      @config_location = location
    end

    # If the "flix_debug" environment variable is set to any value, or this
    # property is set, extra logging information will be sent to stdout.
    property debug : Bool = Defaults.debug
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

    # :ditto:
    def processes : Int
      @processes ||= ENV["flix_processes"]?.try &.to_i || 1
    rescue e : ArgumentError
      @processes = 1
    end

    # :ditto:
    def processes=(other)
      @processes = other.to_i
    end

    # The path on which to POST sign in info to request a new JWT.
    property sign_in_endpoint : String = Defaults.sign_in_endpoint
    # Setting this to true disables authentication entirely.
    property allow_unauthorized : Bool = ENV["KEMAL_ENV"]? == "test"

    property key_file : String?
    property cert_file : String?

    def use_ssl?
      key_file && cert_file
    end

    def initialize(@config_location : String = Defaults.config_location,
                   @dirs = Defaults.media_dirs)
      check_config_dir
      @processes = processes.to_i
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      scan_dirs
    end

    # The file where authentication tokens are stored
    setter users_file : String?

    # :ditto:
    def users_file : String
      @users_file ||= File.join @config_location, "users.auth"
    end

    property log_file : IO = STDOUT
    setter log_level : Logger::Severity?

    def log_level
      @log_level ||= debug ? Logger::DEBUG : Logger::INFO
    end

    # A central interface for debug and admin log messages.
    def logger : Logger
      @logger ||= Logger.new io: log_file, level: log_level
    end

    # The scanned and initialized root Scanner::MediaDirectory.
    def dirs : Array(Scanner::MediaDirectory)
      @initialized_dirs
    end

    # An array of paths to valid directories that contain valid media files.
    # Currently supported media types are defined by the Flix::Scanner::MimeType
    # enum.
    def dirs=(@dirs : Array(String))
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      scan_dirs
    end

    {% if env("KEMAL_ENV") == "test" %}
    def dirs=(@initialized_dirs : Array(Scanner::MediaDirectory))
    end
    {% end %}

    setter testing : Bool?

    def testing?
      @testing ||= ENV["KEMAL_ENV"]? === "test"
    end

    def reload!
      sync_metadata!
      scan_dirs
    end

    {% for filetype in {:photo, :video} %}
    property all_{{filetype.id}}s = Hash(String, Scanner::{{filetype.id.capitalize}}File).new
    {% end %}

    # run this once all the photos and videos are found. It assigns any photo
    # with a similar name as a video to be that video's thumbnail.
    #
    # The comparison uses the video file basename formatted with
    # `#get_title_from`, passed to `Levenshtein.find`, using the default
    # tolerance.
    def associate_thumbnails : Void
      all_img_names = all_photos.map &.name
      all_videos.each do |hash, vid|
        if found_name = Levenshtein.find(vid.name, all_img_names)
          vid.thumbnail = all_photos.find { |img| img.name === found_name }
        end
      end
    end

    private def scan_dirs
      all_photos = [] of Scanner::PhotoFile
      all_videos = [] of Scanner::VideoFile
      @dirs.each do |dirpath|
        if data = Scanner::MediaDirectory.from_file_path? dirpath, all_videos, all_photos
          dir, vids, photos = data
          if dir.is_dir?
            @initialized_dirs << dir.as Scanner::MediaDirectory
            @all_videos.concat vids
            @all_photos.concat photos
          end
        end
      end
      @initialized_dirs.reject! &.nil?
      @all_videos = all_videos.map { |vid| {vid.hash, vid} }.to_h
      @all_photos = all_photos.map { |vid| {vid.hash, vid} }.to_h
      p! @initialized_dirs.to_json, @all_photos.to_json, @all_videos.to_json
      associate_thumbnails
    end

    private def check_config_dir
      if (File.exists? @config_location) && !(File.directory? @config_location)
        raise "expected to find directory at #{@config_location}"
      else
        Dir.mkdir_p @config_location
      end
    end
  end
end
