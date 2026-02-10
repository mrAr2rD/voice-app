class BatchJob < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  has_many :transcriptions, dependent: :nullify
  has_many :voice_generations, dependent: :nullify
  has_many :translations, dependent: :nullify

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3, partially_completed: 4 }

  JOB_TYPES = %w[transcription voice_generation translation].freeze

  validates :job_type, presence: true, inclusion: { in: JOB_TYPES }
  validates :name, length: { maximum: 255 }

  scope :recent, -> { order(created_at: :desc) }

  after_update_commit :broadcast_updated

  serialize :settings, coder: JSON

  def progress_percentage
    return 0 if total_items.zero?
    ((completed_items + failed_items).to_f / total_items * 100).round
  end

  def in_progress?
    pending? || processing?
  end

  def update_progress!
    items = case job_type
    when "transcription" then transcriptions
    when "voice_generation" then voice_generations
    when "translation" then translations
    else []
    end

    self.completed_items = items.where(status: :completed).count
    self.failed_items = items.where(status: :failed).count

    if completed_items + failed_items >= total_items
      self.status = failed_items.positive? && completed_items.positive? ? :partially_completed : (failed_items.positive? ? :failed : :completed)
    end

    save!
  end

  def job_type_display
    case job_type
    when "transcription" then "Транскрибация"
    when "voice_generation" then "Озвучка"
    when "translation" then "Перевод"
    else job_type.titleize
    end
  end

  private

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_batch_jobs",
      target: dom_id(self),
      partial: "batch_jobs/batch_job",
      locals: { batch_job: self }
    )
  end
end
