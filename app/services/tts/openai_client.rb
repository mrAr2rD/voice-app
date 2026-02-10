module Tts
  class OpenaiClient
    API_URL = "https://api.openai.com/v1".freeze

    VOICES = [
      { id: "alloy", name: "Alloy", description: "Нейтральный, сбалансированный голос" },
      { id: "echo", name: "Echo", description: "Тёплый, вовлекающий мужской" },
      { id: "fable", name: "Fable", description: "Выразительный, британский акцент" },
      { id: "onyx", name: "Onyx", description: "Глубокий, авторитетный мужской" },
      { id: "nova", name: "Nova", description: "Тёплый, дружелюбный женский" },
      { id: "shimmer", name: "Shimmer", description: "Чистый, оптимистичный женский" }
    ].freeze

    MODELS = %w[tts-1 tts-1-hd].freeze

    def initialize
      @api_key = Setting.openai_api_key
      raise "OpenAI API key not configured" unless @api_key.present?
    end

    def generate(text:, voice_id:, model: "tts-1", speed: 1.0)
      response = connection.post("/v1/audio/speech") do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: model,
          input: text,
          voice: voice_id,
          speed: speed.clamp(0.25, 4.0),
          response_format: "mp3"
        }.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    def voices
      { success: true, data: VOICES }
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
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
        error_message = error_body.is_a?(Hash) ? error_body.dig("error", "message") : error_body
        { success: false, error: "API error (#{response.status}): #{error_message}" }
      end
    end
  end
end
