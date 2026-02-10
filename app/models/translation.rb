class Translation < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :source_text, presence: true, length: { maximum: 50000 }
  validates :target_language, presence: true

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  LANGUAGES = [
    ["Русский", "ru"],
    ["Английский", "en"],
    ["Немецкий", "de"],
    ["Французский", "fr"],
    ["Испанский", "es"],
    ["Итальянский", "it"],
    ["Португальский", "pt"],
    ["Китайский", "zh"],
    ["Японский", "ja"],
    ["Корейский", "ko"],
    ["Арабский", "ar"],
    ["Турецкий", "tr"],
    ["Польский", "pl"],
    ["Украинский", "uk"]
  ].freeze

  MODELS = [
    ["Gemini 2.0 Flash (быстрый)", "google/gemini-2.0-flash-001"],
    ["GPT-4o Mini (баланс)", "openai/gpt-4o-mini"],
    ["Claude 3.5 Haiku (качество)", "anthropic/claude-3.5-haiku"]
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

  def model_name
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
end
