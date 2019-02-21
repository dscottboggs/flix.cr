# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "magic"

PHOTO_FILE_TYPES = {Flix::Scanner::MimeType::JPEG, Flix::Scanner::MimeType::PNG}
VIDEO_FILE_TYPES = {Flix::Scanner::MimeType::MP4, Flix::Scanner::MimeType::WebM, Flix::Scanner::MimeType::Matroska}

enum Flix::Scanner::MimeType
  Directory
  MP4
  WebM
  MKV
  Matroska            = MKV
  JPEG
  PNG
  OctetStream
  PlainText
  PotentialSubtitle   = PlainText
  SubRipSubtitles
  SubStationSubtitles
  JSONSubtitles
  # Any mime-type except application/octet-stream gets sent as a whole to the
  # client, whereas octet-stream
  Streamable = OctetStream

  def to_s
    case self
    when MP4                          then "video/mp4"
    when WebM                         then "video/webm"
    when MKV, Matroska                then "video/x-matroska"
    when JPEG                         then "image/jpeg"
    when PNG                          then "image/png"
    when Directory                    then "inode/directory"
    when PlainText, PotentialSubtitle then "text/plain"
    when SubRipSubtitles              then "text/x-srt"
    when SubStationSubtitles          then "text/x-substation"
    when JSONSubtitles                then "application/json"
    when Streamable, OctetStream      then "application/octet-stream"
    else raise "got invalid variant: #{self.inspect}"
    end
  end

  def self.from_s(string : String)
    case string
    when .starts_with? "video/mp4"                then MP4
    when .starts_with? "video/webm"               then WebM
    when .starts_with? "video/x-matroska"         then Matroska
    when .starts_with? "image/jpeg"               then JPEG
    when .starts_with? "image/png"                then PNG
    when .starts_with? "application/octet-stream" then OctetStream
    when .starts_with? "text/plain"               then PotentialSubtitle
    when .starts_with? "text/x-srt"               then SubRipSubtitles
    when .starts_with? "text/x-substation"        then SubStationSubtitles
    when .starts_with? "application/json"         then JSONSubtitles
    when "inode/directory"                        then Directory
    end
  end

  def self.from_s!(string)
    from_s(string) || raise %<unknown mime "#{string}">
  end

  def self.of(path)
    ft = Magic.mime_type.of? path
    if ft
      filetype = self.from_s ft
      if filetype == OctetStream && path.ends_with? ".mp4"
        MP4
      else
        filetype
      end
    end
  end

  def self.of!(path)
    self.of(path) || raise %<unknown mime "#{Magic.mime_type.of? path}" for "#{path}",.>
  end

  def is_a_video?
    VIDEO_FILE_TYPES.includes? self
  end

  def is_a_photo?
    PHOTO_FILE_TYPES.includes? self
  end

  def is_a_dir?
    self === Directory
  end

  def could_be_subtitles?
    {
      PotentialSubtitle, SubRipSubtitles, SubStationSubtitles, JSONSubtitles,
    }.includes? self
  end

  def is_a_subtitle?
    {SubRipSubtitles, SubStationSubtitles, JSONSubtitles}.includes? self
  end

  def is_substation?
    self === SubStationSubtitles
  end
end
