class YoutubeCredential < ApplicationRecord
  belongs_to :user

  encrypts :access_token_encrypted
  encrypts :refresh_token_encrypted

  validates :user_id, uniqueness: true

  def expired?
    return true unless expires_at
    expires_at < Time.current
  end

  def connected?
    access_token_encrypted.present? && channel_id.present?
  end

  def needs_refresh?
    return true unless expires_at
    expires_at < 5.minutes.from_now
  end
end
