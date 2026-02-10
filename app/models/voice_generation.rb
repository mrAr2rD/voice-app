class VoiceGeneration < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true
  has_one_attached :audio_file

  enum :provider, { elevenlabs: 0, openai: 1 }
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :text, presence: true, length: { maximum: 5000 }
  validates :voice_id, presence: true
  validates :provider, presence: true

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  def text_preview(length = 50)
    text.truncate(length)
  end

  def provider_display_name
    case provider
    when "elevenlabs" then "ElevenLabs"
    when "openai" then "OpenAI"
    else provider.titleize
    end
  end

  def in_progress?
    pending? || processing?
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_voice_generations",
      target: "voice_generations",
      partial: "voice_generations/voice_generation",
      locals: { voice_generation: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_voice_generations",
      target: dom_id(self),
      partial: "voice_generations/voice_generation",
      locals: { voice_generation: self }
    )
  end
end
