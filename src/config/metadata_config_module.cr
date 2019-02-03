module Flix
  # Methods which work with the metadata config file. This is `include`d into
  # the `Flix.config` singleton.
  module MetadataConfiguration
    @testing_metadata_file : IO::Memory?
    @metadata_file : IO?

    def metadata_file(mode = "r")
      yield metadata_file mode
    end

    def metadata_file(mode = "r") : IO
      @metadata_file ||= if testing?
                           @testing_metadata_file ||= IO::Memory.new
                         else
                           File.open(File.join(config_location, "metadata.yaml"), mode: mode)
                         end
    end

    def sync_metadata!
      Flix::MetadataConfig.synchronize!
    end
  end
end
