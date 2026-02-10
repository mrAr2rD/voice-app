class CreateVideoBuilders < ActiveRecord::Migration[8.1]
  def change
    create_table :video_builders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, foreign_key: true

      t.string :title
      t.text :description

      # Статус обработки
      t.integer :status, default: 0, null: false
      t.integer :progress, default: 0
      t.text :error_message

      # Настройки видео
      t.string :video_mode, default: "trim"
      t.float :output_duration

      # Настройки субтитров
      t.boolean :subtitles_enabled, default: false
      t.string :subtitles_style, default: "default"
      t.string :subtitles_position, default: "bottom"
      t.integer :subtitles_font_size, default: 24

      # YouTube публикация
      t.string :youtube_video_id
      t.string :youtube_status, default: "not_published"
      t.datetime :published_at
      t.text :youtube_title
      t.text :youtube_description
      t.text :youtube_tags

      t.timestamps
    end

    add_index :video_builders, :status
    add_index :video_builders, :youtube_status
    add_index :video_builders, :created_at
  end
end
