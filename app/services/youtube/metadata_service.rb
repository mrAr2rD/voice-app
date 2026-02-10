module Youtube
  class MetadataService < ApplicationService
    def initialize(video_builder, video_id, metadata)
      @video_builder = video_builder
      @video_id = video_id
      @metadata = metadata
      @credential = video_builder.user.youtube_credential
    end

    def call
      return failure("YouTube не подключён") unless @credential&.connected?

      update_metadata
    rescue StandardError => e
      Rails.logger.error "YouTube MetadataService error: #{e.message}"
      failure(e.message)
    end

    private

    def update_metadata
      refresh_result = TokenRefreshService.call(@credential)
      return failure(refresh_result.error) if refresh_result.failure?

      body = {
        id: @video_id,
        snippet: {
          title: @metadata[:title],
          description: @metadata[:description],
          tags: @metadata[:tags],
          categoryId: "22"
        }
      }

      if @metadata[:privacy_status].present?
        body[:status] = { privacyStatus: @metadata[:privacy_status] }
      end

      conn = Faraday.new(url: "https://www.googleapis.com/youtube/v3")
      response = conn.put("/videos") do |req|
        req.params["part"] = body[:status] ? "snippet,status" : "snippet"
        req.headers["Authorization"] = "Bearer #{@credential.access_token_encrypted}"
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      unless response.success?
        return failure("Ошибка обновления метаданных: #{response.body}")
      end

      success(true)
    end
  end
end
