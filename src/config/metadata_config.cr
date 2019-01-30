require "yaml"
require "../scanner/metadata"

module Flix
  module MetadataConfig
    struct ConfigFile
      include YAML::Serializable

      property folders : Hash(String, Flix::Scanner::FileMetadata::ConfigData)
    end
    extend self

    def synchronize!
      File.open File.join(Flix.config.config_location, "metadata.yaml") do |file|
        cfg = ConfigFile.from_yaml file
        Flix.config.dirs.each do |dir|
          dir.merge! cfg[dir.hash]
        end
      end
    rescue e : Errno
      raise e unless e.value === Errno::ENOENT
    ensure
      File.open(File.join(Flix.config.config_location, "metadata.yml"), mode: "w") do |file|
        YAML.build file do |builder|
          builder.mapping do
            builder.scalar "folders"
            builder.mapping do
              Flix.config.dirs.each do |dir|
                builder.scalar dir.hash
                builder.scalar dir.config_data
              end
            end
          end
        end
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
