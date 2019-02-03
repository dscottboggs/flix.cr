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

    # This method reads in any new data from the config file, and merges it with
    # the existing data. Since there are some common false positive situations
    # one can run into when this method is run, it ignores certain errors. As
    # such, it's technically possible for you to overwrite your override config
    # file with one containing the old data. It shouldn't really be possible
    # though, because the only ignored errors are:
    #  - When invalid YAML occurs within the first line and first 9 letters
    #    width-wise of the YAML file; **OR**
    #  - When the file does not already exist.
    # If you encounter a situation where the config file is overwritten by the
    # existing state which isn't one of these situations, or in which these
    # situations cause a legitimate error to be ignored, please raise an issue
    # at https://github.com/dscottboggs/flix.cr/issues/new.
    #
    # The rationale for choosing these error cases to ignore is that the
    # beginning of the config file is always either "---\nfolders:\n" or
    # "folders:\n", the shorter of which is 9 letters long including the
    # newline.
    #
    # If a YAML parsing error occurs, an exception WILL be thrown, so for every
    # case except the inital synchronize after launch, be sure to add a resuce
    # block. We don't want the whole app crashing if invalid YAML is encountered
    # by a remotely-triggered metadata refresh.
    def synchronize!
      read_in
    rescue error : YAML::ParseException
      # A YAML::ParseException will be raised if the file (or in the case of
      # testing, IO) is empty. We should bail here for any other parse
      # exceptions, because if we don't the next step is to overwrite it.
      unless (error.line_number < 2) && (error.column_number < 10)
        raise YAML::ParseException.new(
          message: String.build do |emsg|
            emsg << "while reading in << YAML\n"
            emsg << Flix.config.metadata_file.rewind.gets_to_end
            emsg << "\nYAML\ngot error:\n"
            emsg << error.message
          end,
          line_number: error.line_number,
          column_number: error.column_number)
      end
    rescue error : Errno
      # In the case that the file isn't found, we're just going to ignore this
      # error and move on with the `ensure` block. Otherwise, the exception is
      # actually a problem and should be raised.
      raise error unless error.errno === Errno::ENOENT
    ensure
      write_current_state
    end

    private def read_in
      cfg = ConfigFile.from_yaml Flix.config.metadata_file
      Flix.config.dirs.each do |dir|
        dir.merge! cfg.folders[dir.hash]
      end
    end

    def write_current_state
      mf = Flix.config.metadata_file mode: "w"
      mf.rewind
      if mf.responds_to? :truncate
        mf.truncate
      elsif mf.responds_to? :clear
        mf.clear
      else
        raise "Metadata file is not able to be truncated." if Flix.config.testing?
      end
      ConfigFile.new(dirs: Flix.config.dirs).to_yaml mf
    ensure
      Flix.config.metadata_file(mode: "w").close unless Flix.config.testing?
    end
  end
end
