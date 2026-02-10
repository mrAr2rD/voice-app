class SocialAccount < ApplicationRecord
  belongs_to :user

  encrypts :access_token_encrypted, :refresh_token_encrypted

  PLATFORMS = [
    [ "TikTok", "tiktok" ],
    [ "Instagram", "instagram" ],
    [ "VK", "vk" ],
    [ "Telegram", "telegram" ]
  ].freeze

  enum :status, { active: 0, expired: 1, disconnected: 2 }

  validates :platform, presence: true, inclusion: { in: PLATFORMS.map(&:last) }
  validates :platform, uniqueness: { scope: :user_id }

  scope :connected, -> { where(status: :active) }

  def platform_name
    PLATFORMS.find { |p| p[1] == platform }&.first || platform.titleize
  end

  def access_token
    access_token_encrypted
  end

  def access_token=(value)
    self.access_token_encrypted = value
  end

  def refresh_token
    refresh_token_encrypted
  end

  def refresh_token=(value)
    self.refresh_token_encrypted = value
  end

  def token_expired?
    expires_at.present? && expires_at < Time.current
  end

  def platform_icon
    case platform
    when "tiktok" then "tiktok"
    when "instagram" then "instagram"
    when "vk" then "vk"
    when "telegram" then "telegram"
    else "share"
    end
  end

  def platform_color
    case platform
    when "tiktok" then "#00f2ea"
    when "instagram" then "#E4405F"
    when "vk" then "#0077FF"
    when "telegram" then "#0088cc"
    else "#6366f1"
    end
  end
end
