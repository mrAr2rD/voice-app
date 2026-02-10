class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # Ключи настроек
  KEYS = {
    # Функционал
    transcription_enabled: { default: "true", type: :boolean, description: "Включить транскрибацию" },
    voice_generation_enabled: { default: "true", type: :boolean, description: "Включить озвучку" },

    # API ключи
    nexara_api_key: { default: "", type: :string, description: "API ключ Nexara (транскрибация)" },
    openai_api_key: { default: "", type: :string, description: "API ключ OpenAI (TTS)" },
    elevenlabs_api_key: { default: "", type: :string, description: "API ключ ElevenLabs (TTS)" },
    openrouter_api_key: { default: "", type: :string, description: "API ключ OpenRouter" },

    # Провайдеры по умолчанию
    default_tts_provider: { default: "openai", type: :string, description: "TTS провайдер по умолчанию" },
    default_transcription_provider: { default: "nexara", type: :string, description: "Провайдер транскрибации" }
  }.freeze

  class << self
    def get(key)
      key = key.to_s
      setting = find_by(key: key)
      value = setting&.value || KEYS.dig(key.to_sym, :default) || ""

      case KEYS.dig(key.to_sym, :type)
      when :boolean
        value.to_s == "true"
      when :integer
        value.to_i
      else
        value
      end
    end

    def set(key, value)
      key = key.to_s
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s
      setting.description ||= KEYS.dig(key.to_sym, :description)
      setting.save!
      value
    end

    def transcription_enabled?
      get(:transcription_enabled)
    end

    def voice_generation_enabled?
      get(:voice_generation_enabled)
    end

    def nexara_api_key
      key = get(:nexara_api_key)
      key.present? ? key : Rails.application.credentials.dig(:nexara, :api_key)
    end

    def openai_api_key
      key = get(:openai_api_key)
      key.present? ? key : Rails.application.credentials.dig(:openai, :api_key)
    end

    def elevenlabs_api_key
      key = get(:elevenlabs_api_key)
      key.present? ? key : Rails.application.credentials.dig(:elevenlabs, :api_key)
    end

    def openrouter_api_key
      key = get(:openrouter_api_key)
      key.present? ? key : Rails.application.credentials.dig(:openrouter, :api_key)
    end
  end
end
