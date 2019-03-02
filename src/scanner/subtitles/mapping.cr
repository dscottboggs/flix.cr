require "./languages"

module Flix::Scanner
  class SubtitleFile < FileMetadata
    class Mapping
      DefaultLocale = Languages.from_language_code DEFAULT_LOCALE_STRING
      property subtitles : Array(SubtitleFile) do
        [] of SubtitleFile
      end
      delegate :size, :empty?, to: subtitles

      def initialize; end

      def initialize(@subtitles); end

      def self.new(subtitles_mapping : Hash(Languages, SubtitleFile))
        subtitles_mapping.each { |lang, sub| sub.langugage = lang }
        new subtitles_mapping.values
      end

      # Find the SubtitleFile associated with the given language, if one exists.
      def []?(lang : Languages)
        lang = DefaultLocale if lang.none?
        subtitles.find { |subs| subs.language == lang }
      end

      # :ditto:
      # If the given language code is invalid, this will raise an
      # InvalidLanguageCode. To find an associated subtitle based on a possibly
      # invalid lanaguage code, you should instead do
      # ```
      # if lang = Languages.from_language_code? possibly_invalid_input
      #   if subs = mapping[lang]?
      #     # do something with subs
      #   else
      #     # not found
      #   end
      # else
      #   # invalid language code
      # end
      # ```
      @[AlwaysInline]
      def []?(lang_code : String)
        self[Languages.from_language_code lang_code]?
      end

      # Returns the `SubtitleFile` associated with the default locale for the
      # server, or raises an `IndexError` if there's no subtitles assocated with
      # the default locale.
      @[AlwaysInline]
      def in_default_locale
        self[DefaultLocale]
      end

      # Returns the `SubtitleFile` associated with the default locale for the
      # server, or `nil` if there's no subtitles assocated with
      # the default locale.
      @[AlwaysInline]
      def in_default_locale?
        self[DefaultLocale]?
      end

      # Find the subtitle in this mapping that is associated with either the
      # two-character language code or the Languages enum value. If there is
      # no value associated with the specified key, an IndexError will be
      # raised.
      def [](lang)
        self[lang]? || raise IndexError.new "Subtitles in #{lang.inspect} not found."
      end

      # Associate the given language with the given subtitles file and store the
      # subtitles file in this mapping. If a subtitle is already associated
      # with this language, it will be removed.
      def []=(lang : Languages, subs : SubtitleFile)
        subs.language = lang
        self << subs
      end

      # Associate the language assocaited with the given language code with the
      # given subtitles file and store the subtitles file in this mapping. If a
      # subtitle is already associated with this language, it will be removed.
      def []=(lang : String, subs : SubtitleFile)
        self[Languages.from_language_code lang] = subs
      end

      # Store the given subtitles file in this mapping. If a subtitle is
      # already associated with this language, it will be removed.
      def <<(subs : SubtitleFile)
        if existing = subtitles.index { |s| s.language == subs.language }
          subtitles.delete_at index: existing
        end
        subtitles << subs
      end

      # Yield the pair of each subtitle's language and the SubtitleFile to the
      # block.
      def each : Void
        subtitles.each { |subs| yield subs.language, subs }
      end

      # Yield the pair of each subtitle's language and the SubtitleFile to the
      # block, which MUST return an equivalent pair. The equivalent pair will
      # then be stored in this mapping, overriding the previous entry if
      # applicable.
      def map!(&block : (Languages, SubtitleFile) -> Tuple(Language, SubtitleFile)) : Void
        each do |lang, subs|
          lang, subs = yield language, subs
          self[lang] = subs
        end
      end

      # :ditto:
      def map!(&block : (Languages, SubtitleFile) -> Tuple(String, SubtitleFile)) : Void
        each do |lang, subs|
          lang, subs = yield language, subs
          self[Language.from_language_code lang] = subs
        end
      end

      # Yield the pair of each subtitle's language and the SubtitleFile to the
      # block, which MUST return a SubtitleFile. The SubtitleFile will then be
      # stored in this mapping, as associated with its `#language` property,
      # overriding the previous entry if applicable.
      def map!(&block : (Languages, SubtitleFile) -> SubtitleFile) : Void
        each do |lang, subs|
          subs = yield language, subs
          self[subs.language] = subs
        end
      end

      # Yield the pair of each subtitle's language and the SubtitleFile to the
      # block. Returns an iterable of the return values of the block.
      def map
        subtitles.map do |subs|
          yield subs.language, subs
        end
      end
    end
  end
end
