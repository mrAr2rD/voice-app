module Youtube
  class ThumbnailService < ApplicationService
    def initialize(video_builder, video_id)
      @video_builder = video_builder
      @video_id = video_id
      @credential = video_builder.user.youtube_credential
    end

    def call
      return failure("Нет обложки") unless @video_builder.thumbnail.attached?
      return failure("YouTube не подключён") unless @credential&.connected?

      upload_thumbnail
    rescue StandardError => e
      Rails.logger.error "YouTube ThumbnailService error: #{e.message}"
      failure(e.message)
    end

    private

    def upload_thumbnail
      thumbnail_data = @video_builder.thumbnail.download
      content_type = @video_builder.thumbnail.content_type

      conn = Faraday.new(url: "https://www.googleapis.com/upload/youtube/v3") do |f|
        f.request :multipart
      end

      response = conn.post("/thumbnails/set") do |req|
        req.params["videoId"] = @video_id
        req.headers["Authorization"] = "Bearer #{@credential.access_token_encrypted}"
        req.headers["Content-Type"] = content_type
        req.body = thumbnail_data
      end

      unless response.success?
        return failure("Ошибка загрузки обложки: #{response.body}")
      end

      success(true)
    end
  end
end
