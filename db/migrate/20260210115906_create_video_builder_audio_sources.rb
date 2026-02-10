class CreateVideoBuilderAudioSources < ActiveRecord::Migration[8.1]
  def change
    create_table :video_builder_audio_sources do |t|
      t.references :video_builder, null: false, foreign_key: true
      t.references :voice_generation, foreign_key: true
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :video_builder_audio_sources, [ :video_builder_id, :position ]
  end
end
