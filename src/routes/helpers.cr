module Flix::RouteHelpers
  # this method returns the Proc which gets called when the /nfo endpoint is
  # reached.
  def serve_metadata(to context : HTTP::Server::Context) : Void
    return unless user_found? in_headers_or_params_of: context
    id = context.params.url["id"]? || context.params.query["id"]?
    if id.nil?
      page_not_found
      return
    end
    if video = Flix.config.dirs[video: id]?
      context.response.puts video.nfo.to_json
    elsif photo = Flix.config.dirs[photo: id]?
      context.response.puts photo.nfo.to_json
    else
      page_not_found
    end
  end

  # this method returns the Proc which gets called when the /img endpoint is
  # reached.
  def serve_img(to context : HTTP::Server::Context) : Void
    return unless user_found? in_headers_or_params_of: context
    Flix.logger.debug context.current_user
    id = context.params.url["id"]? || context.params.query["id"]?
    if id.nil?
      page_not_found
      return
    end
    # try grabbing it as a thumbnail for a video first.
    Flix.logger.debug "got photo with ID #{id}"
    if (video = Flix.config.dirs[video: id]) &&
       (photo = video.thumbnail) &&
       (File.exists? photo.path)
      Flix.logger.debug "sending photo #{photo.path} of type #{photo.mime_type}"
      send_file context, path: photo.path, mime_type: photo.mime_type.to_s
    elsif (photo = Flix.config.dirs[photo: id]) &&
          (File.exists? photo.path)
      send_file context, path: photo.path, mime_type: Scanner::MimeType::Streamable.to_s
    else
      page_not_found
    end
  end

  # this method returns the Proc which gets called when the /vid endpoint is
  # reached.
  def serve_video(to context : HTTP::Server::Context) : Void
    return unless user_found? in_headers_or_params_of: context
    id = context.params.url["id"]? || context.params.query["id"]?
    if id.nil?
      page_not_found
      return
    end
    Flix.logger.debug "got video with ID #{id}"
    if video = Flix.config.dirs[video: id]
      Flix.logger.debug "rendering video #{video.path} of type #{video.mime_type}"
      send_file context, path: video.path, mime_type: Scanner::MimeType::Streamable.to_s
    else
      page_not_found
    end
  rescue e : Errno
    raise e unless {Errno::EPIPE, Errno::ECONNRESET}.includes? e.errno
  end

  def serve_subtitles(to context : HTTP::Server::Context) : Void
    return unless user_found? in_headers_or_params_of: context
    id = context.params.url["id"]? || context.params.query["id"]? || return page_not_found
    lang = if (lang_code = context.params.url["lang"]? || context.params.query["lang"]?)
             Languages.from_language_code lang_code
           else
             Languages::DefaultLocale
           end
    Flix.logger.debug "got request for subtitles with ID #{id.inspect} and language #{lang.inspect}"
    if subs = Flix.config.dirs[subtitle: id]? || video_for(id, lang)
      # some relevant subtitles were found either by ID or by their associated
      # video's ID
      Flix.logger.debug "found subtitles in #{subs.language} at #{subs.path}"
      subs.send to: context do
        page_not_found
      end
    else
      page_not_found
    end
  end

  private def video_for(id : String, language : Languages) : Scanner::SubtitleFile?
    if vid = Flix.config.dirs[video: id]?
      Flix.logger.debug "found video #{vid.inspect} looking for #{language.inspect} subtitles"
      vid.subtitles[language]?
    end
  end

  # Returns true if the user is found or if
  # Flix::Configuration.allow_unauthorized is set. Otherwise, sets the status
  # to *403 Forbidden* and returns false.
  def user_found?(in_headers_or_params_of context)
    if context.current_user.try(&.["name"]?) || Flix.config.allow_unauthorized
      true
    else
      context.response.status_code = 403
      false
    end
  end

  # Set the status code and render an appropriate 404 Not Found.
  macro page_not_found
    context.response.status_code = 404
    render_404
    nil
  end
end
