class User < ApplicationRecord
  has_secure_password

  has_many :transcriptions, dependent: :destroy
  has_many :voice_generations, dependent: :destroy
  has_many :translations, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :admins, -> { where(admin: true) }

  def admin?
    admin == true
  end
end
