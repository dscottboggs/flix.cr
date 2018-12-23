require "yaml"
require "./yaml/*"
require "./persistence"

# Allow saving the current state to a file, and overwriteing the current state
# based on the contents of said file, in YAML format.
class Flix::YAMLPersistence < Flix::Persistence
  class YAMLSerializer < Flix::Persistence::ConfigSerializer
    include ::YAML::Serializable
    include ::YAML::Serializable::Strict
    include_media
  end
  def initialize(@location, @data)
    super
  end
  def initialize(@location)
    super
  end
  sync_methods format: YAML
end
