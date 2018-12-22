require "yaml"
require "./persistence"
require "./yaml/*"

# Allow saving the current state to a file, and overwriteing the current state
# based on the contents of said file, in YAML format.
class Flix::Scanner::YAMLPersistence < Flix::Scanner::Persistence
  struct ConfigSerializer
    include ::YAML::Serializable
  end

  sync_methods format: YAML
end
