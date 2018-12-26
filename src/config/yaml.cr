module Flix
  module Serialization
    module YAML
      extend self

      class_property location = File.join(Flix.config.config_location, "metadata.yml")

      def sync!(data : Array(Scanner::FileMetadata::Serialized))
        sync! data, with: location
      end
      def sync!(data : Array(Scanner::FileMetadata::Serialized), with filepath : String)
        File.open(filepath, mode: "rw") { |file| sync! data, with: file }
      end

      def sync!(data : Array(Scanner::FileMetadata::Serialized), with io : IO)
        new_data = read from: io
        io.rewind
        data = merge data, with: new_data
        write data, to: io
        data
      end

      def merge(old_data : Array(Scanner::FileMetadata::Serialized),
                with new_data : Array(Scanner::FileMetadata::Serialized)) : Array(Scanner::FileMetadata::Serialized)
        output_data = [] of Scanner::FileMetadata::Serialized
        old_data.each do |serialized_dir|
          dir = Scanner::FileMetadata::Directory.deserialize serialized_dir
          new_dirs = new_data.select &.same_path? as: dir
          raise "\
            found #{new_dirs.size} top-level directories with #{dir.name} as \
            their title." if new_dirs.size > 1
          output_data << dir.merge new_dirs[0]
        end
        output_data
      end

      def read
        File.open location do |file|
          read from: file
        end
      end
      def read(from io : IO)
        read YAML.parse io
      end
      def read(yaml : YAML::Any)
        if media = read_in["media"]?.try &.as_a?
          media.map do |dir|
            Scanner::Directory.deserialize dir
          end
        end
      end

      def write(data : Array(Scanner::FileMetadata::Serialized))
        write data, to: @@location
      end
      def write(data : Array(Scanner::FileMetadata::Serialized), to filepath : String)
        File.open filepath, mode: "w" do |file|
          write data, to: file
        end
      end
      def write(data : Array(Scanner::FileMetadata::Serialized), to io : IO)
        data.to_yaml io
      end
    end
  end
end
