require "kemal"

module Flix
  extend self

  def serve_video(env)
    id = env.params.url["id"]? || env.params.query["id"]?
    if id.nil?
      render_404
      return
    end
    video = Scanner::FileMetadata.all_videos[id]?
    if video.nil?
      render_404
    else
      send_file env, video.not_nil!.path
    end
  end

  def serve_image(env)
    id = env.params.url["id"]? || env.params.query["id"]?
    if id.nil?
      render_404
      return
    end
    photo = Scanner::FileMetadata.all_photos[id]?
    if photo.nil?
      video = Scanner::FileMetadata.all_videos[id]?
      if video.nil?
        render_404
        return
      else
        photo = video.thumbnail
      end
    end
    if photo.nil?
      render_404
    else
      if File.exists? photo.not_nil!.path
        send_file env, photo.not_nil!.path
      else
        render_404
      end
    end
  end
end
