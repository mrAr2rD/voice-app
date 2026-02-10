class CreateVoiceGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :voice_generations do |t|
      t.references :user, null: false, foreign_key: true
      t.text :text, null: false
      t.integer :provider, null: false, default: 0
      t.string :voice_id, null: false
      t.string :voice_name
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end
    add_index :voice_generations, :status
    add_index :voice_generations, :created_at
  end
end
