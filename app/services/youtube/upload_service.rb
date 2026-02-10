module Youtube
  class UploadService < ApplicationService
    CHUNK_SIZE = 8 * 1024 * 1024

    def initialize(video_builder)
      @video_builder = video_builder
      @credential = video_builder.user.youtube_credential
    end

    def call
      return failure("YouTube не подключён") unless @credential&.connected?
      return failure("Видео не готово") unless @video_builder.output_video.attached?

      @video_builder.update!(youtube_status: "publishing")

      refresh_result = TokenRefreshService.call(@credential)
      return failure(refresh_result.error) if refresh_result.failure?

      upload_video
    rescue StandardError => e
      Rails.logger.error "YouTube UploadService error: #{e.message}\n#{e.backtrace.join("\n")}"
      @video_builder.update!(youtube_status: "failed")
      failure(e.message)
    end

    private

    def upload_video
      video_file = download_video

      metadata = {
        snippet: {
          title: @video_builder.youtube_title.presence || @video_builder.display_title,
          description: @video_builder.youtube_description.presence || "",
          tags: parse_tags(@video_builder.youtube_tags),
          categoryId: "22"
        },
        status: {
          privacyStatus: "private",
          selfDeclaredMadeForKids: false
        }
      }

      upload_url = initiate_resumable_upload(metadata)
      video_id = perform_upload(upload_url, video_file)

      if @video_builder.thumbnail.attached?
        ThumbnailService.call(@video_builder, video_id)
      end

      @video_builder.update!(
        youtube_video_id: video_id,
        youtube_status: "published",
        published_at: Time.current
      )

      success(video_id)
    ensure
      FileUtils.rm_f(video_file) if video_file && File.exist?(video_file)
    end

    def download_video
      path = Rails.root.join("tmp", "youtube_upload_#{@video_builder.id}.mp4")
      File.open(path, "wb") do |file|
        @video_builder.output_video.download { |chunk| file.write(chunk) }
      end
      path.to_s
    end

    def initiate_resumable_upload(metadata)
      conn = Faraday.new(url: "https://www.googleapis.com/upload/youtube/v3")
      response = conn.post("/videos") do |req|
        req.params["uploadType"] = "resumable"
        req.params["part"] = "snippet,status"
        req.headers["Authorization"] = "Bearer #{@credential.access_token_encrypted}"
        req.headers["Content-Type"] = "application/json"
        req.headers["X-Upload-Content-Type"] = "video/mp4"
        req.body = metadata.to_json
      end

      unless response.success?
        error_info = extract_error_message(response)
        raise "Ошибка инициализации загрузки: #{error_info}"
      end

      response.headers["location"]
    end

    def perform_upload(upload_url, video_file)
      file_size = File.size(video_file)
      uploaded = 0

      File.open(video_file, "rb") do |file|
        while uploaded < file_size
          chunk = file.read(CHUNK_SIZE)
          chunk_size = chunk.bytesize
          range_end = uploaded + chunk_size - 1

          conn = Faraday.new do |f|
            f.options.timeout = 300
          end

          response = conn.put(upload_url) do |req|
            req.headers["Authorization"] = "Bearer #{@credential.access_token_encrypted}"
            req.headers["Content-Type"] = "video/mp4"
            req.headers["Content-Length"] = chunk_size.to_s
            req.headers["Content-Range"] = "bytes #{uploaded}-#{range_end}/#{file_size}"
            req.body = chunk
          end

          if response.status == 200 || response.status == 201
            data = JSON.parse(response.body)
            return data["id"]
          elsif response.status == 308
            new_uploaded = parse_range(response.headers["range"])
            raise "Загрузка не прогрессирует" if new_uploaded <= uploaded
            uploaded = new_uploaded
          else
            error_info = extract_error_message(response)
            raise "Ошибка загрузки: #{response.status} - #{error_info}"
          end
        end
      end

      raise "Загрузка не завершена"
    end

    def parse_range(range_header)
      return 0 unless range_header
      range_header.split("-").last.to_i + 1
    end

    def parse_tags(tags_string)
      return [] if tags_string.blank?
      tags_string.split(",").map(&:strip).reject(&:blank?)
    end

    def extract_error_message(response)
      data = JSON.parse(response.body)
      data.dig("error", "message") || "Unknown error"
    rescue JSON::ParserError
      "HTTP #{response.status}"
    end
  end
end
