class Project < ApplicationRecord
  belongs_to :user

  has_many :transcriptions, dependent: :nullify
  has_many :translations, dependent: :nullify
  has_many :voice_generations, dependent: :nullify
  has_many :video_builders, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :user_id }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "должен быть в формате HEX (#RRGGBB)" }, allow_blank: true

  scope :recent, -> { order(updated_at: :desc) }

  COLORS = [
    ["Синий", "#3B82F6"],
    ["Фиолетовый", "#8B5CF6"],
    ["Розовый", "#EC4899"],
    ["Красный", "#EF4444"],
    ["Оранжевый", "#F97316"],
    ["Жёлтый", "#EAB308"],
    ["Зелёный", "#22C55E"],
    ["Бирюзовый", "#14B8A6"],
    ["Голубой", "#06B6D4"],
    ["Серый", "#6B7280"]
  ].freeze

  def items_count
    transcriptions.count + translations.count + voice_generations.count + video_builders.count
  end

  def display_color
    color.presence || "#6B7280"
  end
end
