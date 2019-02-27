require "./directory"

module Flix::Scanner
  class SubtitlesOnlyDirectory < MediaDirectory
    def only_subtitles?
      true
    end

    def initialize(copy_of dir : MediaDirectory)
      {% for ivar in @type.instance_vars %}
        @{{ivar.id}} = dir.@{{ivar.id}}
      {% end %}
    end

    def associate_with(this video : VideoFile)
      each_subtitle do |id, subs|
        video.subtitles[subs.language] = subs
      end
    end
  end
end
