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
    default_transcription_provider: { default: "nexara", type: :string, description: "Провайдер транскрибации" },

    # Цены (в центах)
    transcription_cost_per_minute: { default: "0.6", type: :float, description: "Цена транскрибации за минуту (центы)" },
    openai_tts_cost_per_1k_chars: { default: "1.5", type: :float, description: "Цена OpenAI TTS за 1000 символов (центы)" },
    elevenlabs_cost_per_1k_chars: { default: "30", type: :float, description: "Цена ElevenLabs за 1000 символов (центы)" }
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
      when :float
        value.to_f
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

    # Цены
    def transcription_cost_per_minute
      get(:transcription_cost_per_minute)
    end

    def openai_tts_cost_per_1k_chars
      get(:openai_tts_cost_per_1k_chars)
    end

    def elevenlabs_cost_per_1k_chars
      get(:elevenlabs_cost_per_1k_chars)
    end

    def calculate_transcription_cost(duration_seconds)
      minutes = duration_seconds.to_f / 60
      (minutes * transcription_cost_per_minute).round
    end

    def calculate_tts_cost(characters_count, provider)
      chars_in_thousands = characters_count.to_f / 1000
      cost_per_1k = provider == "openai" ? openai_tts_cost_per_1k_chars : elevenlabs_cost_per_1k_chars
      (chars_in_thousands * cost_per_1k).round
    end
  end
end
