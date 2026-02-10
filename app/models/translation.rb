class Translation < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :batch_job, optional: true

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :source_text, presence: true, length: { maximum: 50000 }
  validates :target_language, presence: true

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_update_commit :update_batch_job_progress, if: :batch_job_id?

  LANGUAGES = [
    [ "Русский", "ru" ],
    [ "Английский", "en" ],
    [ "Немецкий", "de" ],
    [ "Французский", "fr" ],
    [ "Испанский", "es" ],
    [ "Итальянский", "it" ],
    [ "Португальский", "pt" ],
    [ "Китайский", "zh" ],
    [ "Японский", "ja" ],
    [ "Корейский", "ko" ],
    [ "Арабский", "ar" ],
    [ "Турецкий", "tr" ],
    [ "Польский", "pl" ],
    [ "Украинский", "uk" ]
  ].freeze

  # Бесплатные модели OpenRouter
  MODELS = [
    [ "DeepSeek V3.2 (рекомендуется)", "deepseek/deepseek-v3.2-20251201" ],
    [ "DeepSeek Chat V3.1", "deepseek/deepseek-chat-v3.1" ],
    [ "Gemini 2.5 Flash", "google/gemini-2.5-flash" ],
    [ "Gemini 2.5 Flash Lite (быстрый)", "google/gemini-2.5-flash-lite" ],
    [ "Grok 4.1 Fast", "x-ai/grok-4.1-fast" ],
    [ "Grok Code Fast", "x-ai/grok-code-fast-1" ],
    [ "Kimi K2.5", "moonshotai/kimi-k2.5-0127" ],
    [ "GPT OSS 120B", "openai/gpt-oss-120b" ]
  ].freeze

  def text_preview(length = 50)
    source_text.truncate(length)
  end

  def language_name(code)
    LANGUAGES.find { |l| l[1] == code }&.first || code
  end

  def source_language_name
    source_language == "auto" ? "Авто" : language_name(source_language)
  end

  def target_language_name
    language_name(target_language)
  end

  def ai_model_name
    MODELS.find { |m| m[1] == model }&.first || model
  end

  def in_progress?
    pending? || processing?
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_translations",
      target: "translations",
      partial: "translations/translation",
      locals: { translation: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_translations",
      target: dom_id(self),
      partial: "translations/translation",
      locals: { translation: self }
    )
  end

  def update_batch_job_progress
    batch_job&.update_progress! if completed? || failed?
  end
end
