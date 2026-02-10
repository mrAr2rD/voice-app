class ClonedVoice < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  has_many_attached :audio_samples

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
  scope :ready, -> { where(status: :completed).where.not(elevenlabs_voice_id: nil) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  def voice_id
    elevenlabs_voice_id
  end

  def ready?
    completed? && elevenlabs_voice_id.present?
  end

  def in_progress?
    pending? || processing?
  end

  def labels_array
    labels.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def labels_array=(arr)
    self.labels = arr.join(", ")
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_cloned_voices",
      target: "cloned_voices",
      partial: "cloned_voices/cloned_voice",
      locals: { cloned_voice: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_cloned_voices",
      target: dom_id(self),
      partial: "cloned_voices/cloned_voice",
      locals: { cloned_voice: self }
    )
  end
end
