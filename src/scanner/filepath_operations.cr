module Flix::Scanner::FilepathOperations
  # If the path is two characters long, return the whole path. Otherwise,
  # check for the ISO 639-1 language code in the filename, as a second file
  # extension like so:
  #
  # ```
  # /path/to/file.en.srt
  #               ^^ ^^^ -- regular filename extension (ignored)
  #               ||-----language code
  # /path/to/videos/thisone/nl.ssa
  #                 ^^      ^^ ^^^--- extension (ignored)
  #                 ||      ||--- language code
  #                 ||--- evaluates to the same title as a video in this dir
  # ```
  # This allows you the freedom to choose from the following file layouts:
  #
  # 1. A file named the same thing as a video, but with the language code
  # extension and file extension instead of the video's extension (I.E.
  # for /path/to/video.mp4: /path/to/video.en.srt)
  # 2. A directory named the same as the video file (with the file extension
  # stripped off) containing one or more subtitles for that video file with:
  #  - files whose name is only their language code
  #  - files which end in `{language code}.{3-char extension}`
  def language_code(found_in filename : String) : String?
    filename = File.basename filename
    return filename if filename.size == 2
    if match = /\.?(\w{2})\.\w{3}$/.match filename
      return match[1]
    end
  end

  def language_code
    language_code found_in: path
  end

  # Strips off the double-extension from a subtitle file with a language code
  # as well as a regular file-extension postfix. It simply calls
  # `.without_extension` twice.
  #
  # For example:
  # ```
  # path = "/path/to/video.es.ssa"
  # include FilepathOperations
  # without_language_code File.basename path               # => "video"
  # without_extension without_extension File.basename path # => "video"
  # ```
  def without_language_code(filepath : String)
    without_extension without_extension filepath
  end

  # `#path` stripped of two file extensions
  def without_language_code
    without_language_code path
  end

  # Uses some heuristics to parse a human-readable title from some common
  # filename conventions.
  #
  # If there are any spaces in the filename this step is skipped and the
  # filename is used verbatim.
  def get_title_from(filepath : String, strip_extension = true) : String
    underscores, dots = 0_u32, 0_u32
    filename = File.basename filepath
    # trim off the extension
    if filename.size - (index = filename.rindex('.') || 0) <= 5
      filename = filename[0..index - 1] if strip_extension
    end
    # count dots and underscores
    filename.each_char do |char|
      # also check for spaces, since we're already iterating over all of them
      return filename if char == ' '
      dots += 1 if char == '.'
      underscores += 1 if char == '_'
    end
    # replace underscores or dots, depending on which has more
    if underscores > 0 || dots > 0
      subchar = if underscores > dots
                  '_'
                else
                  '.'
                end
      return filename
        .gsub(/\\#{subchar}([a-zA-Z])/) { |ss, match| " " + match[0].upcase }
        .gsub(subchar, ' ')
        .gsub(/\s+/, " ")
        .strip
    end
    # no spaces, dots, or underscores, so that leaves us with CamelCase
    filename = filename.gsub '-', " -"
    subs = Hash(Char, Char | String).new
    ('A'..'Z').each { |l| subs[l] = " " + l }
    filename = filename.sub 0, filename[0].upcase

    filename.gsub(subs).strip
  end

  # Just the section at the end of the filename after the final '.', if that
  # dot is less than 5 characters from the end of the filename. Nillable!
  def extension(of_this filename) : String?
    dot_loc = path.rindex '.'
    if dot_loc && dot_loc >= (path.size - 5)
      path[dot_loc..-1]
    end
  end

  # The filename without its `#extension` component. If the `#extension` is
  # `nil`, this is the whole filename.
  def without_extension(filename)
    dot_loc = filename.rindex '.'
    if dot_loc && dot_loc >= (filename.size - 5)
      filename[0..(dot_loc - 1)]
    else
      filename
    end
  end

  def extension
    extension of_this: _filename
  end

  def without_extension
    without_extension _filename
  end

  def to_s
    %{<"#{name}"@#{path}$#{hash}>}
  end
end
