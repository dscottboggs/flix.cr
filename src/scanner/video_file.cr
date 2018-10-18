module Scanner
  class VideoFile < FileMetadata
    def initialize(@path : String, @thumbnail : PhotoFile? = nil)
      @name = self.get_title_from @path
    end
  end
end
