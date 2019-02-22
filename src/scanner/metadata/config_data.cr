# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "yaml"
require "../*"

# A convenience structure for converting to YAML.
abstract class Flix::Scanner::FileMetadata
  alias ConfigData = Union( VideoFile::ConfigData, PhotoFile::ConfigData, MediaDirectory::ConfigData, SubtitleFile::ConfigData )
end
