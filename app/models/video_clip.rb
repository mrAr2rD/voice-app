class VideoClip < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :source_video_builder, class_name: "VideoBuilder", optional: true
  belongs_to :transcription, optional: true

  has_one_attached :source_video
  has_one_attached :output_video

  enum :status, { pending: 0, analyzing: 1, processing: 2, completed: 3, failed: 4 }

  ASPECT_RATIOS = [
    [ "9:16 (TikTok, Reels, Shorts)", "9:16" ],
    [ "1:1 (Instagram Feed)", "1:1" ],
    [ "4:5 (Instagram Portrait)", "4:5" ],
    [ "16:9 (YouTube)", "16:9" ]
  ].freeze

  SUBTITLES_STYLES = [
    [ "Анимированные (TikTok стиль)", "animated" ],
    [ "Стандартные", "default" ],
    [ "Без субтитров", "none" ]
  ].freeze

  validates :start_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :end_time, presence: true, numericality: { greater_than: 0 }
  validate :end_time_after_start_time

  scope :recent, -> { order(created_at: :desc) }
  scope :by_virality, -> { order(virality_score: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  before_save :calculate_duration

  def display_title
    title.presence || "Клип #{formatted_time_range}"
  end

  def formatted_time_range
    "#{format_time(start_time)} - #{format_time(end_time)}"
  end

  def duration_formatted
    return nil unless duration
    minutes = (duration / 60).floor
    seconds = (duration % 60).floor
    format("%d:%02d", minutes, seconds)
  end

  def in_progress?
    pending? || analyzing? || processing?
  end

  def aspect_ratio_display
    ASPECT_RATIOS.find { |r| r[1] == aspect_ratio }&.first || aspect_ratio
  end

  def vertical?
    aspect_ratio == "9:16" || aspect_ratio == "4:5"
  end

  private

  def calculate_duration
    self.duration = end_time - start_time if start_time && end_time
  end

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "должно быть после начала") if end_time <= start_time
  end

  def format_time(seconds)
    return "0:00" unless seconds
    minutes = (seconds / 60).floor
    secs = (seconds % 60).floor
    format("%d:%02d", minutes, secs)
  end

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_video_clips",
      target: "video_clips",
      partial: "video_clips/video_clip",
      locals: { video_clip: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_video_clips",
      target: dom_id(self),
      partial: "video_clips/video_clip",
      locals: { video_clip: self }
    )
  end
end
