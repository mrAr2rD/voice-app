class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  after_save :clear_cache
  after_destroy :clear_cache

  # Ключи настроек
  KEYS = {
    # Основной функционал
    transcription_enabled: { default: "true", type: :boolean, description: "Включить транскрибацию" },
    voice_generation_enabled: { default: "true", type: :boolean, description: "Включить озвучку" },
    translation_enabled: { default: "true", type: :boolean, description: "Включить переводчик" },

    # Новый функционал
    scripts_enabled: { default: "true", type: :boolean, description: "Включить AI сценарии" },
    video_clips_enabled: { default: "true", type: :boolean, description: "Включить клипы Shorts/Reels" },
    cloned_voices_enabled: { default: "true", type: :boolean, description: "Включить клонирование голоса" },
    batch_processing_enabled: { default: "true", type: :boolean, description: "Включить пакетную обработку" },
    social_publishing_enabled: { default: "true", type: :boolean, description: "Включить публикацию в соц.сети" },
    youtube_analytics_enabled: { default: "true", type: :boolean, description: "Включить YouTube аналитику" },

    # API ключи
    nexara_api_key: { default: "", type: :string, description: "API ключ Nexara (транскрибация)" },
    openai_api_key: { default: "", type: :string, description: "API ключ OpenAI (TTS)" },
    elevenlabs_api_key: { default: "", type: :string, description: "API ключ ElevenLabs (TTS)" },
    openrouter_api_key: { default: "", type: :string, description: "API ключ OpenRouter" },

    # Google OAuth для YouTube
    google_client_id: { default: "", type: :string, description: "Google OAuth Client ID" },
    google_client_secret: { default: "", type: :string, description: "Google OAuth Client Secret" },
    app_host: { default: "localhost:3000", type: :string, description: "Хост приложения для OAuth callbacks" },

    # Видео-билдер
    video_builder_enabled: { default: "true", type: :boolean, description: "Включить видео-билдер" },

    # Провайдеры по умолчанию
    default_tts_provider: { default: "openai", type: :string, description: "TTS провайдер по умолчанию" },
    default_transcription_provider: { default: "nexara", type: :string, description: "Провайдер транскрибации" },

    # Цены (в центах)
    transcription_cost_per_minute: { default: "0.6", type: :float, description: "Цена транскрибации за минуту (центы)" },
    openai_tts_cost_per_1k_chars: { default: "1.5", type: :float, description: "Цена OpenAI TTS за 1000 символов (центы)" },
    elevenlabs_cost_per_1k_chars: { default: "30", type: :float, description: "Цена ElevenLabs за 1000 символов (центы)" },
    translation_cost_per_1k_tokens: { default: "0.1", type: :float, description: "Цена перевода за 1000 токенов (центы)" }
  }.freeze

  class << self
    def get(key)
      key = key.to_s
      cache_key = "setting/#{key}"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
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
    end

    def clear_cache_for(key)
      Rails.cache.delete("setting/#{key}")
    end

    def set(key, value)
      key = key.to_s
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s
      setting.description ||= KEYS.dig(key.to_sym, :description)
      setting.save!  # triggers clear_cache callback
      value
    end

    def transcription_enabled?
      get(:transcription_enabled)
    end

    def voice_generation_enabled?
      get(:voice_generation_enabled)
    end

    def translation_enabled?
      get(:translation_enabled)
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

    def google_client_id
      key = get(:google_client_id)
      key.present? ? key : Rails.application.credentials.dig(:google, :client_id)
    end

    def google_client_secret
      key = get(:google_client_secret)
      key.present? ? key : Rails.application.credentials.dig(:google, :client_secret)
    end

    def app_host
      get(:app_host)
    end

    def video_builder_enabled?
      get(:video_builder_enabled)
    end

    def scripts_enabled?
      get(:scripts_enabled)
    end

    def video_clips_enabled?
      get(:video_clips_enabled)
    end

    def cloned_voices_enabled?
      get(:cloned_voices_enabled)
    end

    def batch_processing_enabled?
      get(:batch_processing_enabled)
    end

    def social_publishing_enabled?
      get(:social_publishing_enabled)
    end

    def youtube_analytics_enabled?
      get(:youtube_analytics_enabled)
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

  private

  def clear_cache
    self.class.clear_cache_for(key)
  end
end
