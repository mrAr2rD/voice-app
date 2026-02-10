class CreateClonedVoices < ActiveRecord::Migration[8.1]
  def change
    create_table :cloned_voices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :elevenlabs_voice_id
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.string :labels

      t.timestamps
    end

    add_index :cloned_voices, :status
    add_index :cloned_voices, :elevenlabs_voice_id
  end
end
