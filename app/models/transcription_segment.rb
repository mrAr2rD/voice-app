class TranscriptionSegment < ApplicationRecord
  belongs_to :transcription

  validates :text, presence: true
  validates :start_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :end_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time

  scope :ordered, -> { order(:start_time) }

  def start_time_formatted
    format_time(start_time)
  end

  def end_time_formatted
    format_time(end_time)
  end

  def duration
    end_time - start_time
  end

  def srt_timestamp(time)
    hours = (time / 3600).floor
    minutes = ((time % 3600) / 60).floor
    seconds = (time % 60).floor
    milliseconds = ((time % 1) * 1000).round
    format("%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
  end

  private

  def format_time(time)
    return "0:00" unless time
    minutes = (time / 60).floor
    seconds = (time % 60).floor
    format("%d:%02d", minutes, seconds)
  end

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "должно быть больше времени начала") if end_time <= start_time
  end
end
