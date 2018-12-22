# Allow saving the current state to a file, and overwriting the current state
# based on the contents of said file. This does not include the actual
# serialization module, but depends on one styled like JSON::Serializable or
# YAML::Serializable.
#
# In order to use this, create a class which subclasses this. It must reopen the
# ConfigSerializer struct and include a Serializable module. Then, you must
# define a `#read` and `#write` method on that class. As a convenience, there is
# a `sync_methods` macro which will define those for you if you are using a
# a Serializable module to serialize the config.
#
# Please read the source code for this file as well as the YAML concrete
# implementation at src/persistence/yaml.cr if you intend to use a similar
# technique for a different serialization format.
abstract class Flix::Scanner::Persistence
  struct ConfigSerializer
    property media : Array(MediaDirectory)
    def initialize(@media);end
    def merge(other : self)
      media.merge other.media
    end
  end
  property location : String
  property data : ConfigSerializer
  def initialize(@location, @data)
    sync!
  end
  def initialize(@location)
    @data = read
  end
  def sync!
    from_file = read
    @data.merge from_file
    write @data
  end

  abstract def read : self
  abstract def write(data : ConfigSerializer) : ConfigSerializer

  # define a read and write method for a given format. A `self.from_format` and
  # `#to_format` method must be defined for any given `format`.
  # I.E. using `sync_methods format: YAML` creates read and write methods that
  # use `self.from_yaml` and `#to_yaml`. (`sync_methods :yaml` would work the
  # same)
  macro sync_methods(format)
    # read a file from @location with a {{format.id}}-formatted configuration
    def read : self
      File.open @location do |file|
        ConfigSerializer.from_{{format.id.downcase}} file
      end
    end

    # write {{format.id}}-formatted data to a file at @location
    def write(data) : ConfigSerializer
      File.open @location, mode: "w" do |file|
        data.to_{{format.id.downcase}} file
      end
      data
    end
  end
end
