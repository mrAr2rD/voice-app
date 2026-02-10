module Transcriptions
  class NexaraClient
    API_URL = "https://api.nexara.ru/api/v1/audio/transcriptions".freeze

    def initialize
      @api_key = Setting.nexara_api_key
      raise "Nexara API key not configured" unless @api_key.present?
    end

    def transcribe(file_path, language: nil, diarize: true)
      connection = build_connection

      payload = {
        file: Faraday::Multipart::FilePart.new(file_path, detect_mime_type(file_path)),
        response_format: "verbose_json",
        timestamp_granularities: "segment"
      }
      payload[:language] = language if language.present?
      payload[:diarize] = diarize

      response = connection.post do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.body = payload
      end

      handle_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def build_connection
      Faraday.new(url: API_URL) do |f|
        f.request :multipart
        f.request :url_encoded
        f.response :json
        f.adapter Faraday.default_adapter
        f.options.timeout = 600
        f.options.open_timeout = 30
      end
    end

    def detect_mime_type(file_path)
      extension = File.extname(file_path).downcase
      mime_types = {
        ".mp3" => "audio/mpeg",
        ".wav" => "audio/wav",
        ".m4a" => "audio/mp4",
        ".ogg" => "audio/ogg",
        ".webm" => "audio/webm",
        ".mp4" => "audio/mp4"
      }
      mime_types[extension] || "application/octet-stream"
    end

    def handle_response(response)
      if response.success?
        { success: true, data: response.body }
      else
        error_message = response.body.is_a?(Hash) ? response.body["error"] : response.body
        { success: false, error: "API error (#{response.status}): #{error_message}" }
      end
    end
  end
end
