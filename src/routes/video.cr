require "./handler"
class Flix::VideoHandler < Flix::Handler
  only ["/vid", "/vid/:id"]

  def call(env)
    skip_other_routes

    id = env.params.url["id"]? || env.params.query["id"]?
    if id.nil?
      render_404
      return
    end
    video = Scanner::FileMetadata.all_videos[id]?
    if video.nil?
      render_404
      return
    else
      send_file env, video.not_nil!.path
    end
  end
end
