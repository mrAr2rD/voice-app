class ScheduledPost < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :video_builder, optional: true
  belongs_to :video_clip, optional: true

  enum :status, { pending: 0, scheduled: 1, publishing: 2, published: 3, failed: 4 }

  validates :platform, presence: true
  validate :has_video_source

  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where(status: [ :pending, :scheduled ]).order(scheduled_at: :asc) }
  scope :for_publishing, -> { where(status: :scheduled).where("scheduled_at <= ?", Time.current) }

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated

  def video_source
    video_builder || video_clip
  end

  def video_title
    if video_builder
      video_builder.title
    elsif video_clip
      video_clip.display_title
    end
  end

  def platform_name
    SocialAccount::PLATFORMS.find { |p| p[1] == platform }&.first || platform.titleize
  end

  def hashtags_array
    hashtags.to_s.split(/[\s,]+/).select { |h| h.start_with?("#") || h.present? }.map { |h| h.start_with?("#") ? h : "##{h}" }
  end

  def caption_with_hashtags
    [ caption, hashtags_array.join(" ") ].reject(&:blank?).join("\n\n")
  end

  def scheduled?
    scheduled_at.present? && scheduled_at > Time.current
  end

  def ready_to_publish?
    scheduled_at.present? && scheduled_at <= Time.current && pending?
  end

  private

  def has_video_source
    unless video_builder_id.present? || video_clip_id.present?
      errors.add(:base, "Необходимо выбрать видео")
    end
  end

  def broadcast_created
    broadcast_prepend_to(
      "user_#{user_id}_scheduled_posts",
      target: "scheduled_posts",
      partial: "scheduled_posts/scheduled_post",
      locals: { scheduled_post: self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      "user_#{user_id}_scheduled_posts",
      target: dom_id(self),
      partial: "scheduled_posts/scheduled_post",
      locals: { scheduled_post: self }
    )
  end
end
