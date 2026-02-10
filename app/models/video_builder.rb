class VideoBuilder < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true

  has_many :audio_sources, class_name: "VideoBuilderAudioSource", dependent: :destroy
  has_many :voice_generations, through: :audio_sources

  has_one_attached :source_video
  has_one_attached :source_audio
  has_one_attached :output_video
  has_one_attached :thumbnail
  has_one_attached :subtitles_file
  has_many_attached :background_videos

  enum :status, { draft: 0, processing: 1, completed: 2, failed: 3 }

  validates :title, length: { maximum: 200 }
  validates :video_mode, inclusion: { in: %w[trim loop] }
  validates :subtitles_style, inclusion: { in: %w[default outlined shadow boxed] }, allow_blank: true
  validates :subtitles_position, inclusion: { in: %w[top center bottom] }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  VIDEO_MODES = [
    ["Обрезать под аудио", "trim"],
    ["Зациклить под аудио", "loop"]
  ].freeze

  SUBTITLE_STYLES = [
    ["Стандартный", "default"],
    ["С обводкой", "outlined"],
    ["С тенью", "shadow"],
    ["В рамке", "boxed"]
  ].freeze

  SUBTITLE_POSITIONS = [
    ["Сверху", "top"],
    ["По центру", "center"],
    ["Снизу", "bottom"]
  ].freeze

  def display_title
    title.presence || "Видео ##{id}"
  end

  def video_mode_display
    VIDEO_MODES.find { |m| m[1] == video_mode }&.first || video_mode
  end

  def in_progress?
    draft? || processing?
  end

  def can_publish?
    completed? && output_video.attached? && youtube_status == "not_published"
  end

  def youtube_published?
    youtube_status == "published" && youtube_video_id.present?
  end

  def youtube_url
    return nil unless youtube_video_id.present?
    "https://www.youtube.com/watch?v=#{youtube_video_id}"
  end

  def duration_formatted
    return nil unless output_duration
    minutes = (output_duration / 60).floor
    seconds = (output_duration % 60).floor
    format("%d:%02d", minutes, seconds)
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_video_builders",
      target: "video_builders",
      partial: "video_builders/video_builder",
      locals: { video_builder: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_video_builders",
      target: dom_id(self),
      partial: "video_builders/video_builder",
      locals: { video_builder: self }
    )
  end
end
