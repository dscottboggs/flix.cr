require "yaml"
require "../scanner/metadata"

module Flix
  module MetadataConfig
    struct ConfigFile
      include JSON::Serializable

      property folders : Hash(String, Flix::Scanner::FileMetadata::ConfigData)
    end

    extend self

    def synchronize!
      File.open File.join(Flix.config.config_location, "metadata.yaml") do |file|
        ctx = YAML::ParseContext.new
        doc = YAML::Nodes.parse(file).as YAML::Nodes::Document
        if top_level_untyped = doc.nodes.first?
          if (top_level = top_level_untyped).is_a? YAML::Nodes::Mapping
            case lbl = top_level.nodes.first?
            when .is_a? YAML::Nodes::Scalar
              doc.raise "\
              got yaml node #{lbl.inspect}, expected string \
              literal #{"folders".inspect}" unless lbl.value === "folders"
              if (conf = top_level.nodes[1]?).is_a? YAML::Nodes::Mapping
                conf.each do |key, value|
                  Flix
                  .config
                  .dirs
                  .find { |dir| dir.hash === key }
                  .merge! Flix::Scanner::MediaDirectory::ConfigData.new ctx, value
                end
              else
                lbl.raise "got #{conf.inspect}, expecting config mapping"
              end
            else doc.raise "got first node #{lbl.inspect} of top_level"
            end
          else
            doc.raise "got unexpected node #{top_level.inspect} at top level"
          end
        else
          doc.raise "got empty yaml #{doc.inspect}, #{file.inspect}"
        end
        YAML::PullParser.new content: file do |yaml|
          yaml.read_stream do
            yaml.read_document do
              yaml.read_scalar
              yaml.read_mapping do
                id = yaml.read
                yaml.read_mapping do
                end
              end
            end
          end
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
