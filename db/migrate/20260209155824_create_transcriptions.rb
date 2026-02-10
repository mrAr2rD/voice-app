class CreateTranscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :transcriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.integer :source_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :youtube_url
      t.string :original_filename
      t.float :duration
      t.string :language
      t.text :full_text
      t.text :error_message

      t.timestamps
    end
    add_index :transcriptions, :status
    add_index :transcriptions, :created_at
  end
end
