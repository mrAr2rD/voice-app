class CreateTranscriptionSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :transcription_segments do |t|
      t.references :transcription, null: false, foreign_key: true
      t.text :text, null: false
      t.float :start_time, null: false
      t.float :end_time, null: false
      t.string :speaker
      t.float :confidence

      t.timestamps
    end
    add_index :transcription_segments, :start_time
  end
end
