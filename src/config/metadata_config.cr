require "yaml"
require "../scanner/metadata"

module Flix
  module MetadataConfig
    # A YAML File for lightweight configuration storage and modification.
    struct ConfigFile
      include YAML::Serializable

      # other stuff besides the folders can go here but we don't have anything
      # else for now.
      property folders : Hash(String, Flix::Scanner::MediaDirectory::ConfigData)

      # This constructor accepts the Flix.config.dirs array and turns it into a
      # a mapping appropriate for serialization to the config file.
      def initialize(dirs : Array(Flix::Scanner::FileMetadata))
        @folders = dirs.map { |dir| {dir.hash, dir.config_data} }.to_h
      end
    end

    private def config_file
      Flix.config.metadata_file
    end

    extend self

    def synchronize!
      cfg = ConfigFile.from_yaml Flix.config.metadata_file
      Flix.config.dirs.each do |dir|
        dir.merge! cfg.folders[dir.hash]
      end
    rescue error : YAML::ParseException
      # A YAML::ParseException will be raised if the file (or in the case of
      # testing, IO) is empty. We should bail here for any other parse
      # exceptions, because if we don't the next step is to overwrite it.
      p! error
      unless (error.line_number < 10) && (error.column_number < 10)
        raise YAML::ParseException.new(
          "while reading in <<-YAML\n#{Flix.config.metadata_file.rewind.gets_to_end}\nYAML\n#{error.message}",
          line_number: error.line_number,
          column_number: error.column_number)
      end
    rescue error : Errno
      # In the case that the file isn't found, we're just going to ignore this
      # error and move on with the `ensure` block. Otherwise, the exception is
      # actually a problem and should be raised.
      raise error unless error.errno === Errno::ENOENT
    ensure
      begin
        Flix.config.metadata_file.rewind
        ConfigFile.new(dirs: Flix.config.dirs).to_yaml Flix.config.metadata_file
      ensure
        Flix.config.metadata_file.close unless Flix.config.testing?
      end
    end
  end
end

# Hash(String, Flix::Scanner::FileMetadata::ConfigData).from_json(file).folders.each do |id, conf|
#   Flix
#   .config
#   .dirs
#   .find? { |dir| dir.hash === id }
#   .try(&.merge conf)
