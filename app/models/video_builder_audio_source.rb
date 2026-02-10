class VideoBuilderAudioSource < ApplicationRecord
  belongs_to :video_builder
  belongs_to :voice_generation, optional: true

  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position) }

  def audio_file
    voice_generation&.audio_file
  end

  def display_name
    if voice_generation.present?
      voice_generation.text_preview(30)
    else
      "Аудио источник ##{position + 1}"
    end
  end
end
