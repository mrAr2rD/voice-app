class Script < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  SCRIPT_TYPES = [
    [ "Туториал", "tutorial" ],
    [ "Обзор продукта", "review" ],
    [ "Продающее видео", "sales" ],
    [ "Образовательное", "educational" ],
    [ "Развлекательное", "entertainment" ],
    [ "Новости", "news" ],
    [ "Интервью", "interview" ],
    [ "Подкаст", "podcast" ]
  ].freeze

  DURATIONS = [
    [ "Короткое (30 сек - 1 мин)", 60 ],
    [ "Стандартное (2-3 мин)", 180 ],
    [ "Среднее (5-7 мин)", 420 ],
    [ "Длинное (10-15 мин)", 900 ]
  ].freeze

  MODELS = [
    [ "DeepSeek V3.2 (рекомендуется)", "deepseek/deepseek-v3.2-20251201" ],
    [ "DeepSeek Chat V3.1", "deepseek/deepseek-chat-v3.1" ],
    [ "Gemini 2.5 Flash", "google/gemini-2.5-flash" ],
    [ "Gemini 2.5 Flash Lite (быстрый)", "google/gemini-2.5-flash-lite" ],
    [ "Grok 4.1 Fast", "x-ai/grok-4.1-fast" ],
    [ "Kimi K2.5", "moonshotai/kimi-k2.5-0127" ],
    [ "GPT OSS 120B", "openai/gpt-oss-120b" ]
  ].freeze

  validates :topic, presence: true, length: { maximum: 1000 }
  validates :script_type, presence: true, inclusion: { in: SCRIPT_TYPES.map(&:last) }
  validates :title, length: { maximum: 255 }

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  def script_type_name
    SCRIPT_TYPES.find { |t| t[1] == script_type }&.first || script_type.titleize
  end

  def model_name
    MODELS.find { |m| m[1] == model }&.first || model
  end

  def duration_name
    DURATIONS.find { |d| d[1] == duration_seconds }&.first || "#{duration_seconds} сек"
  end

  def word_count
    content.to_s.split.size
  end

  def estimated_duration_minutes
    (word_count / 150.0).round(1)
  end

  def in_progress?
    pending? || processing?
  end

  def display_title
    title.presence || topic.truncate(50)
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_scripts",
      target: "scripts",
      partial: "scripts/script",
      locals: { script: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_scripts",
      target: dom_id(self),
      partial: "scripts/script",
      locals: { script: self }
    )
  end
end
