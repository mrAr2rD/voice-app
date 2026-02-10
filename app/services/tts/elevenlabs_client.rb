module Tts
  class ElevenlabsClient
    API_URL = "https://api.elevenlabs.io/v1".freeze

    DEFAULT_VOICES = [
      { id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", description: "Calm, young female" },
      { id: "AZnzlk1XvdvUeBnXmlld", name: "Domi", description: "Strong, confident female" },
      { id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", description: "Soft, warm female" },
      { id: "ErXwobaYiN019PkySvjV", name: "Antoni", description: "Well-rounded male" },
      { id: "MF3mGyEYCl7XYWbV9V6O", name: "Elli", description: "Young, emotional female" },
      { id: "TxGEqnHWrfWFTfGW9XjX", name: "Josh", description: "Deep, narrative male" },
      { id: "VR6AewLTigWG4xSOukaG", name: "Arnold", description: "Crisp, elderly male" },
      { id: "pNInz6obpgDQGcFmaJgB", name: "Adam", description: "Deep, mature male" },
      { id: "yoZ06aMxZJJ28mfd3POQ", name: "Sam", description: "Raspy, young male" }
    ].freeze

    def initialize
      @api_key = Setting.elevenlabs_api_key
      raise "ElevenLabs API key not configured" unless @api_key.present?
    end

    def generate(text:, voice_id:, model_id: "eleven_multilingual_v2")
      response = connection.post("/v1/text-to-speech/#{voice_id}") do |req|
        req.headers["xi-api-key"] = @api_key
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "audio/mpeg"
        req.body = {
          text: text,
          model_id: model_id,
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75
          }
        }.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    def voices
      response = connection.get("/v1/voices") do |req|
        req.headers["xi-api-key"] = @api_key
      end

      if response.success?
        data = JSON.parse(response.body)
        { success: true, data: data["voices"] }
      else
        { success: true, data: DEFAULT_VOICES }
      end
    rescue StandardError
      { success: true, data: DEFAULT_VOICES }
    end

    def clone_voice(name:, description:, files:, labels: {})
      conn = Faraday.new(url: API_URL) do |f|
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.options.timeout = 300
        f.options.open_timeout = 60
      end

      payload = {
        name: name,
        description: description
      }

      labels.each do |key, value|
        payload["labels[#{key}]"] = value
      end

      files.each_with_index do |file_data, index|
        payload["files"] = Faraday::Multipart::FilePart.new(
          file_data[:io],
          file_data[:content_type] || "audio/mpeg",
          file_data[:filename] || "sample_#{index}.mp3"
        )
      end

      response = conn.post("/v1/voices/add") do |req|
        req.headers["xi-api-key"] = @api_key
        req.body = payload
      end

      handle_json_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    def delete_voice(voice_id:)
      response = connection.delete("/v1/voices/#{voice_id}") do |req|
        req.headers["xi-api-key"] = @api_key
      end

      if response.success?
        { success: true }
      else
        handle_json_response(response)
      end
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    def get_voice(voice_id:)
      response = connection.get("/v1/voices/#{voice_id}") do |req|
        req.headers["xi-api-key"] = @api_key
      end

      handle_json_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def handle_json_response(response)
      if response.success?
        data = JSON.parse(response.body)
        { success: true, data: data }
      else
        error_body = JSON.parse(response.body) rescue response.body
        error_message = error_body.is_a?(Hash) ? (error_body["detail"] || error_body["message"]) : error_body
        { success: false, error: "API error (#{response.status}): #{error_message}" }
      end
    end

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.response :raise_error
        f.adapter Faraday.default_adapter
        f.options.timeout = 120
        f.options.open_timeout = 30
      end
    end

    def handle_response(response)
      if response.success?
        { success: true, data: response.body }
      else
        error_body = JSON.parse(response.body) rescue response.body
        error_message = error_body.is_a?(Hash) ? error_body["detail"] : error_body
        { success: false, error: "API error (#{response.status}): #{error_message}" }
      end
    end
  end
end
