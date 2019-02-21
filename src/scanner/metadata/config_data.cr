# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "yaml"
require "../*"

# A convenience structure for converting to YAML.
abstract class Flix::Scanner::FileMetadata
  # :nodoc:
  Inherited = { VideoFile, PhotoFile, MediaDirectory, SubtitleFile }

  # The union between all types inherited from this interface
  {%begin%}
  alias ConfigData = {%for t, i in Inherited%}Flix::Scanner::{{t.id}}::ConfigData {%if i<(Inherited.size-1)%}| {%end%}{%end%}
  {%end%}
end
