module Transcriptions
  class OpenrouterClient
    API_URL = "https://openrouter.ai/api/v1".freeze

    # Whisper model через OpenRouter
    TRANSCRIPTION_MODEL = "openai/whisper-large-v3".freeze

    def initialize
      @api_key = Rails.application.credentials.dig(:openrouter, :api_key)
      raise "OpenRouter API key not configured" unless @api_key
    end

    def transcribe(audio_path, language: nil)
      # OpenRouter не поддерживает напрямую Whisper API
      # Используем альтернативный подход через chat completion с аудио
      # Для прямой транскрибации лучше использовать Nexara или OpenAI Whisper

      { success: false, error: "OpenRouter не поддерживает прямую транскрибацию аудио. Используйте Nexara API." }
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.request :multipart
        f.adapter Faraday.default_adapter
        f.options.timeout = 300
        f.options.open_timeout = 30
      end
    end
  end
end
