require "magic"

PHOTO_FILE_TYPES = {Flix::Scanner::MimeType::JPEG, Flix::Scanner::MimeType::PNG}
VIDEO_FILE_TYPES = {Flix::Scanner::MimeType::MP4, Flix::Scanner::MimeType::WebM, Flix::Scanner::MimeType::Matroska}

enum Flix::Scanner::MimeType
  MP4
  WebM
  MKV
  Matroska    = MKV
  JPEG
  PNG
  OctetStream

  def to_s
    case self
    when MP4  then "video/mp4"
    when WebM then "video/webm"
    when MKV  then "video/x-matroska"
    when JPEG then "image/jpeg"
    when PNG  then "image/png"
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
    self.of_file(path) || raise %<unknown mime "#{string}" for "#{path}",.>
  end

  def is_a_video?
    VIDEO_FILE_TYPES.includes? self
  end

  def is_a_photo?
    PHOTO_FILE_TYPES.includes? self
  end
end
