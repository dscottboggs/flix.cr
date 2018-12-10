# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
module Flix
  class Configuration
    property port
    property config_location
    property debug = !ENV["flix_debug"]?.nil?
    property webroot : String = ENV["flix_webroot"]? || File.join(
      File.dirname(Dir.current), "flix_webui", "build"
    )
    setter dirs
    @logger : Logger?
    @initialized_dirs : Array(Scanner::MediaDirectory)
    setter processes : Int32?

    def processes : Int
      @processes ||= ENV["flix_processes"]?.try &.to_i || 1
    rescue e : ArgumentError
      @processes = 1
    end

    def initialize(@config_location : String,
                   @port : UInt16,
                   @dirs = Array(String).new)
      if @dirs.empty?
        @dirs = default_dirs
      end
      # this must be the same as #dirs=, but @initialized_dirs needs to be
      # initialized directly from within the constructor. Watch for changes!
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      @dirs.each do |dir|
        if (i_dir = Scanner::FileMetadata.from_file_path? dir) && i_dir.not_nil!.is_dir?
          @initialized_dirs << i_dir.not_nil!.as(Scanner::MediaDirectory)
        end
      end
      Flix::Scanner::FileMetadata.associate_thumbnails
    end

    def logger : Logger
      if @logger.nil?
        @logger = Logger.new STDOUT, level:  Logger::WARN
      else
        @logger.not_nil!
      end
    end

    def dirs : Array(Scanner::MediaDirectory)
      @initialized_dirs.reject &.nil?
    end

    def dirs=(dirs : Array(String))
      @initialized_dirs = Array(Scanner::MediaDirectory).new
      @dirs.each do |dir|
        if (i_dir = Scanner::FileMetadata.from_file_path? dir) && i_dir.not_nil!.is_dir?
          @initialized_dirs << i_dir.not_nil!.as(Scanner::MediaDirectory)
        end
      end
      Flix::Scanner::FileMetadata.associate_thumbnails
      @initialized_dirs
    end

    # The default directory of media to serve up.
    def default_dirs
      # TODO: make better
      [File.join(ENV["HOME"], "Videos", "Public")]
    end
  end
end
