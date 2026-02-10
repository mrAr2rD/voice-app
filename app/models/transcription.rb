class Transcription < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :project, optional: true
  has_many :transcription_segments, dependent: :destroy
  has_one_attached :source_file
  has_one_attached :extracted_audio

  enum :source_type, { audio_upload: 0, video_upload: 1, youtube_url: 2 }
  enum :status, { pending: 0, processing: 1, extracting_audio: 2, transcribing: 3, completed: 4, failed: 5 }

  validates :source_type, presence: true
  validates :youtube_url, presence: true, if: :youtube_url?
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(&[\w=-]*)?\z},
    message: "должен быть валидным YouTube URL"
  }, allow_blank: true
  validates :source_file, attached: true, unless: :youtube_url?
  validates :source_file, content_type: {
    in: %w[
      audio/mpeg audio/mp4 audio/aac audio/flac audio/ogg
      audio/vnd.wave audio/x-wav audio/x-flac audio/vorbis
      video/mp4 video/webm video/quicktime video/x-msvideo
      video/x-matroska video/ogg video/mpeg
      application/ogg
    ],
    message: "должен быть аудио или видео файлом"
  }, size: { less_than: 500.megabytes, message: "должен быть меньше 500MB" }, if: :source_file_attached?

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  def display_title
    title.presence || original_filename.presence || "Транскрибация ##{id}"
  end

  def audio_file_for_transcription
    extracted_audio.attached? ? extracted_audio : source_file
  end

  def needs_audio_extraction?
    video_upload? || youtube_url?
  end

  def duration_formatted
    return nil unless duration
    minutes = (duration / 60).floor
    seconds = (duration % 60).floor
    format("%d:%02d", minutes, seconds)
  end

  def in_progress?
    pending? || processing? || extracting_audio? || transcribing?
  end

  private

  def source_file_attached?
    source_file.attached?
  end

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_transcriptions",
      target: "transcriptions",
      partial: "transcriptions/transcription",
      locals: { transcription: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_transcriptions",
      target: dom_id(self),
      partial: "transcriptions/transcription",
      locals: { transcription: self }
    )
  end
end
