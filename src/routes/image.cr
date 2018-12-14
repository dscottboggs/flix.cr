require "./handler"

module Flix
  class ImageHandler < Flix::Handler
    only ["/img", "/img/:id"]

    def call(env)
      skip_other_routes

      id = env.params.url["id"]? || env.params.query["id"]?
      if id.nil?
        render_404
        return
      end
      photo = Scanner::FileMetadata.all_photos[id]?
      Flix.logger.debug("found photo at #{photo.path}") unless photo.nil?
      if photo.nil?
        video = Scanner::FileMetadata.all_videos[id]?
        if video.nil?
          render_404
          return
        else
          Flix.logger.debug "found video #{video} with thumbnail <#{video.thumbnail.inspect}>"
          photo = video.thumbnail
          Flix.logger.debug("found photo at #{photo.path}") unless photo.nil?
        end
      end
      if photo.nil?
        Flix.logger.warn "nil photo for id #{id}"
        render_404
        return
      else
        if File.exists? photo.not_nil!.path
          Flix.logger.debug "serving image at #{photo.not_nil!.path} for id #{id}"
          send_file env, photo.not_nil!.path
        else
          Flix.logger.warn "file not found at #{photo.not_nil!.path}"
          render_404
          return
        end
      end
    end
  end
end