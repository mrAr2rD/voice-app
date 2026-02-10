class CreateVideoClips < ActiveRecord::Migration[8.1]
  def change
    create_table :video_clips do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :source_video_builder, foreign_key: { to_table: :video_builders }
      t.references :transcription, foreign_key: true
      t.string :title
      t.integer :status, default: 0, null: false
      t.float :start_time, null: false
      t.float :end_time, null: false
      t.float :duration
      t.string :aspect_ratio, default: "9:16"
      t.text :error_message
      t.float :virality_score
      t.text :highlight_reason
      t.boolean :subtitles_enabled, default: true
      t.string :subtitles_style, default: "animated"

      t.timestamps
    end

    add_index :video_clips, :status
    add_index :video_clips, :created_at
    add_index :video_clips, :virality_score
  end
end
