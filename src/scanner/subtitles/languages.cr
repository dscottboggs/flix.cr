# An enumeration of all valid languages and their associated codes.
# Source: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
enum Languages
  {% begin %}
  # :nodoc:
  #
  # This contains the data used to build up the Enum. However, since we want
  # type safety, this data should never be accessed at runtime, instead using
  # methods on the Languages enum to ensure that a valid variant is received.
  {%
    language_data = {
      ab: {name: "Abkhaz", native_name: "аҧсуа"},
      aa: {name: "Afar", native_name: "Afaraf"},
      af: {name: "Afrikaans", native_name: "Afrikaans"},
      ak: {name: "Akan", native_name: "Akan"},
      sq: {name: "Albanian", native_name: "Shqip"},
      am: {name: "Amharic", native_name: "አማርኛ"},
      ar: {name: "Arabic", native_name: "العربية"},
      an: {name: "Aragonese", native_name: "Aragonés"},
      hy: {name: "Armenian", native_name: "Հայերեն"},
      as: {name: "Assamese", native_name: "অসমীয়া"},
      av: {name: "Avaric", native_name: "авар мацӀ"},
      ae: {name: "Avestan", native_name: "avesta"},
      ay: {name: "Aymara", native_name: "aymar aru"},
      az: {name: "Azerbaijani", native_name: "azərbaycan dili"},
      bm: {name: "Bambara", native_name: "bamanankan"},
      ba: {name: "Bashkir", native_name: "башҡорт теле"},
      eu: {name: "Basque", native_name: "euskara"},
      be: {name: "Belarusian", native_name: "Беларуская"},
      bn: {name: "Bengali", native_name: "বাংলা"},
      bh: {name: "Bihari", native_name: "भोजपुरी"},
      bi: {name: "Bislama", native_name: "Bislama"},
      bs: {name: "Bosnian", native_name: "bosanski jezik"},
      br: {name: "Breton", native_name: "brezhoneg"},
      bg: {name: "Bulgarian", native_name: "български език"},
      my: {name: "Burmese", native_name: "ဗမာစာ"},
      ca: {name: "Catalan; Valencian", native_name: "Català"},
      ch: {name: "Chamorro", native_name: "Chamoru"},
      ce: {name: "Chechen", native_name: "нохчийн мотт"},
      ny: {name: "Chichewa; Chewa; Nyanja", native_name: "chiCheŵa"},
      zh: {name: "Chinese", native_name: "中文 (Zhōngwén)"},
      cv: {name: "Chuvash", native_name: "чӑваш чӗлхи"},
      kw: {name: "Cornish", native_name: "Kernewek"},
      co: {name: "Corsican", native_name: "corsu"},
      cr: {name: "Cree", native_name: "ᓀᐦᐃᔭᐍᐏᐣ"},
      hr: {name: "Croatian", native_name: "hrvatski"},
      cs: {name: "Czech", native_name: "česky"},
      da: {name: "Danish", native_name: "dansk"},
      dv: {name: "Divehi; Dhivehi; Maldivian;", native_name: "ދިވެހި"},
      nl: {name: "Dutch", native_name: "Nederlands"},
      en: {name: "English", native_name: "English"},
      eo: {name: "Esperanto", native_name: "Esperanto"},
      et: {name: "Estonian", native_name: "eesti"},
      ee: {name: "Ewe", native_name: "Eʋegbe"},
      fo: {name: "Faroese", native_name: "føroyskt"},
      fj: {name: "Fijian", native_name: "vosa Vakaviti"},
      fi: {name: "Finnish", native_name: "suomi"},
      fr: {name: "French", native_name: "français"},
      ff: {name: "Fula; Fulah; Pulaar; Pular", native_name: "Fulfulde"},
      gl: {name: "Galician", native_name: "Galego"},
      ka: {name: "Georgian", native_name: "ქართული"},
      de: {name: "German", native_name: "Deutsch"},
      el: {name: "Greek, Modern", native_name: "Ελληνικά"},
      gn: {name: "Guaraní", native_name: "Avañeẽ"},
      gu: {name: "Gujarati", native_name: "ગુજરાતી"},
      ht: {name: "Haitian; Haitian Creole", native_name: "Kreyòl ayisyen"},
      ha: {name: "Hausa", native_name: "Hausa"},
      he: {name: "Hebrew (modern)", native_name: "עברית"},
      hz: {name: "Herero", native_name: "Otjiherero"},
      hi: {name: "Hindi", native_name: "हिन्दी"},
      ho: {name: "Hiri Motu", native_name: "Hiri Motu"},
      hu: {name: "Hungarian", native_name: "Magyar"},
      ia: {name: "Interlingua", native_name: "Interlingua"},
      id: {name: "Indonesian", native_name: "Bahasa Indonesia"},
      ie: {name: "Interlingue", native_name: "Originally called Occidental; then Interlingue after WWII"},
      ga: {name: "Irish", native_name: "Gaeilge"},
      ig: {name: "Igbo", native_name: "Asụsụ Igbo"},
      ik: {name: "Inupiaq", native_name: "Iñupiaq"},
      io: {name: "Ido", native_name: "Ido"},
      is: {name: "Icelandic", native_name: "Íslenska"},
      it: {name: "Italian", native_name: "Italiano"},
      iu: {name: "Inuktitut", native_name: "ᐃᓄᒃᑎᑐᑦ"},
      ja: {name: "Japanese", native_name: "日本語 (にほんご／にっぽんご)"},
      jv: {name: "Javanese", native_name: "basa Jawa"},
      kl: {name: "Kalaallisut, Greenlandic", native_name: "kalaallisut"},
      kn: {name: "Kannada", native_name: "ಕನ್ನಡ"},
      kr: {name: "Kanuri", native_name: "Kanuri"},
      ks: {name: "Kashmiri", native_name: "कश्मीरी"},
      kk: {name: "Kazakh", native_name: "Қазақ тілі"},
      km: {name: "Khmer", native_name: "ភាសាខ្មែរ"},
      ki: {name: "Kikuyu, Gikuyu", native_name: "Gĩkũyũ"},
      rw: {name: "Kinyarwanda", native_name: "Ikinyarwanda"},
      ky: {name: "Kirghiz, Kyrgyz", native_name: "кыргыз тили"},
      kv: {name: "Komi", native_name: "коми кыв"},
      kg: {name: "Kongo", native_name: "KiKongo"},
      ko: {name: "Korean", native_name: "한국어 (韓國語)"},
      ku: {name: "Kurdish", native_name: "Kurdî"},
      kj: {name: "Kwanyama, Kuanyama", native_name: "Kuanyama"},
      la: {name: "Latin", native_name: "latine"},
      lb: {name: "Luxembourgish, Letzeburgesch", native_name: "Lëtzebuergesch"},
      lg: {name: "Luganda", native_name: "Luganda"},
      li: {name: "Limburgish, Limburgan, Limburger", native_name: "Limburgs"},
      ln: {name: "Lingala", native_name: "Lingála"},
      lo: {name: "Lao", native_name: "ພາສາລາວ"},
      lt: {name: "Lithuanian", native_name: "lietuvių kalba"},
      lu: {name: "Luba-Katanga", native_name: ""},
      lv: {name: "Latvian", native_name: "latviešu valoda"},
      gv: {name: "Manx", native_name: "Gaelg"},
      mk: {name: "Macedonian", native_name: "македонски јазик"},
      mg: {name: "Malagasy", native_name: "Malagasy fiteny"},
      ms: {name: "Malay", native_name: "bahasa Melayu"},
      ml: {name: "Malayalam", native_name: "മലയാളം"},
      mt: {name: "Maltese", native_name: "Malti"},
      mi: {name: "Māori", native_name: "te reo Māori"},
      mr: {name: "Marathi (Marāṭhī)", native_name: "मराठी"},
      mh: {name: "Marshallese", native_name: "Kajin M̧ajeļ"},
      mn: {name: "Mongolian", native_name: "монгол"},
      na: {name: "Nauru", native_name: "Ekakairũ Naoero"},
      nv: {name: "Navajo, Navaho", native_name: "Diné bizaad"},
      nb: {name: "Norwegian Bokmål", native_name: "Norsk bokmål"},
      nd: {name: "North Ndebele", native_name: "isiNdebele"},
      ne: {name: "Nepali", native_name: "नेपाली"},
      ng: {name: "Ndonga", native_name: "Owambo"},
      nn: {name: "Norwegian Nynorsk", native_name: "Norsk nynorsk"},
      no: {name: "Norwegian", native_name: "Norsk"},
      ii: {name: "Nuosu", native_name: "ꆈꌠ꒿ Nuosuhxop"},
      nr: {name: "South Ndebele", native_name: "isiNdebele"},
      oc: {name: "Occitan", native_name: "Occitan"},
      oj: {name: "Ojibwe, Ojibwa", native_name: "ᐊᓂᔑᓈᐯᒧᐎᓐ"},
      cu: {name: "Old Church Slavonic, Church Slavic, Church Slavonic, Old Bulgarian, Old Slavonic", native_name: "ѩзыкъ словѣньскъ"},
      om: {name: "Oromo", native_name: "Afaan Oromoo"},
      or: {name: "Oriya", native_name: "ଓଡ଼ିଆ"},
      os: {name: "Ossetian, Ossetic", native_name: "ирон æвзаг"},
      pa: {name: "Panjabi, Punjabi", native_name: "ਪੰਜਾਬੀ"},
      pi: {name: "Pāli", native_name: "पाऴि"},
      fa: {name: "Persian", native_name: "فارسی"},
      pl: {name: "Polish", native_name: "polski"},
      ps: {name: "Pashto, Pushto", native_name: "پښتو"},
      pt: {name: "Portuguese", native_name: "Português"},
      qu: {name: "Quechua", native_name: "Runa Simi"},
      rm: {name: "Romansh", native_name: "rumantsch grischun"},
      rn: {name: "Kirundi", native_name: "kiRundi"},
      ro: {name: "Romanian, Moldavian, Moldovan", native_name: "română"},
      ru: {name: "Russian", native_name: "русский язык"},
      sa: {name: "Sanskrit (Saṁskṛta)", native_name: "संस्कृतम्"},
      sc: {name: "Sardinian", native_name: "sardu"},
      sd: {name: "Sindhi", native_name: "सिन्धी"},
      se: {name: "Northern Sami", native_name: "Davvisámegiella"},
      sm: {name: "Samoan", native_name: "gagana faa Samoa"},
      sg: {name: "Sango", native_name: "yângâ tî sängö"},
      sr: {name: "Serbian", native_name: "српски језик"},
      gd: {name: "Scottish Gaelic; Gaelic", native_name: "Gàidhlig"},
      sn: {name: "Shona", native_name: "chiShona"},
      si: {name: "Sinhala, Sinhalese", native_name: "සිංහල"},
      sk: {name: "Slovak", native_name: "slovenčina"},
      sl: {name: "Slovene", native_name: "slovenščina"},
      so: {name: "Somali", native_name: "Soomaaliga"},
      st: {name: "Southern Sotho", native_name: "Sesotho"},
      es: {name: "Spanish; Castilian", native_name: "español"},
      su: {name: "Sundanese", native_name: "Basa Sunda"},
      sw: {name: "Swahili", native_name: "Kiswahili"},
      ss: {name: "Swati", native_name: "SiSwati"},
      sv: {name: "Swedish", native_name: "svenska"},
      ta: {name: "Tamil", native_name: "தமிழ்"},
      te: {name: "Telugu", native_name: "తెలుగు"},
      tg: {name: "Tajik", native_name: "тоҷикӣ"},
      th: {name: "Thai", native_name: "ไทย"},
      ti: {name: "Tigrinya", native_name: "ትግርኛ"},
      bo: {name: "Tibetan Standard, Tibetan, Central", native_name: "བོད་ཡིག"},
      tk: {name: "Turkmen", native_name: "Türkmen"},
      tl: {name: "Tagalog", native_name: "Wikang Tagalog"},
      tn: {name: "Tswana", native_name: "Setswana"},
      to: {name: "Tonga (Tonga Islands)", native_name: "faka Tonga"},
      tr: {name: "Turkish", native_name: "Türkçe"},
      ts: {name: "Tsonga", native_name: "Xitsonga"},
      tt: {name: "Tatar", native_name: "татарча"},
      tw: {name: "Twi", native_name: "Twi"},
      ty: {name: "Tahitian", native_name: "Reo Tahiti"},
      ug: {name: "Uighur, Uyghur", native_name: "Uyƣurqə"},
      uk: {name: "Ukrainian", native_name: "українська"},
      ur: {name: "Urdu", native_name: "اردو"},
      uz: {name: "Uzbek", native_name: "zbek"},
      ve: {name: "Venda", native_name: "Tshivenḓa"},
      vi: {name: "Vietnamese", native_name: "Tiếng Việt"},
      vo: {name: "Volapük", native_name: "Volapük"},
      wa: {name: "Walloon", native_name: "Walon"},
      cy: {name: "Welsh", native_name: "Cymraeg"},
      wo: {name: "Wolof", native_name: "Wollof"},
      fy: {name: "Western Frisian", native_name: "Frysk"},
      xh: {name: "Xhosa", native_name: "isiXhosa"},
      yi: {name: "Yiddish", native_name: "ייִדיש"},
      yo: {name: "Yoruba", native_name: "Yorùbá"},
      za: {name: "Zhuang, Chuang", native_name: "Saɯ cueŋƅ"}}
  %}
  None = 0
  DefaultLocale = None
  {% for code, lang in language_data %}
  {% if lang[:name] %}# {{lang[:native_name]}} -- AKA {{ lang[:name].id }}
  {% end %} {{ lang[:name].gsub(/\(.+\)/, "").gsub(/[\s-;,]/, " ").split(' ').map(&.capitalize).join("").id }} {% end %}
  # The default locale/None enum value means to use the system locale.

  def language_code
    {% begin %}
    case self
    {% for code, lang in language_data %}
    when {{ lang[:name].gsub(/\(.+\)/, "").gsub(/[\s-;,]/, " ").split(' ').map(&.capitalize).join("").id }}
      "{{code.id}}" {% end %}
    when DefaultLocale then DEFAULT_LOCALE_STRING
    else raise "invalid enum variant #{self.inspect}"
    end
    {% end %}
  end

  def self.from_language_code(code : String)
    {% begin %}
    case code
    {% for code, lang in language_data %}
    when code then {{ lang[:name].gsub(/\(.+\)/, "").gsub(/[\s-;,]/, " ").split(' ').map(&.capitalize).join("").id }}
    {% end %}
    else DefaultLocale
    end
    {% end %}
  end

  def self.from_language_code(null_value : Nil)
    DefaultLocale
  end
  {% end %}
  #
  # private macro constantize(stringliteral)
  #   {{stringliteral.split(' ').map(&.capitalize.gsub /\(.+\)/, "" ).join("").split('-').map(&.capitalize).join("").id}}
  # end

end

# Checks the environment variables $LANG, $LANGUAGE, $LC_ALL, and $LC_NAME for
# the default locale. The first two letters (the ISO 639-1 code) are what is
# stored.
#
# To avoid having to deal with null cases, if none of these environment
# variables are set, this defaults to "en". I realize this is not ideal, but
# if the environment variables are not set, we have no other way of gathering
# this information. If you know of any additional sources by which we could
# check for the ISO 639-1 code, please open an issue or PR.
DEFAULT_LOCALE_STRING = ( ENV["LANG"]? ||
                          ENV["LANGUAGE"]? ||
                          ENV["LC_ALL"]? ||
                          ENV["LC_NAME"]? ||
                          "en"
                        )[0..1]