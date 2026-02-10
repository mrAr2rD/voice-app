class CreateTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :translations do |t|
      t.references :user, null: false, foreign_key: true
      t.text :source_text, null: false
      t.text :translated_text
      t.string :source_language, default: "auto"
      t.string :target_language, null: false
      t.string :model, default: "google/gemini-2.0-flash-001"
      t.integer :tokens_used, default: 0
      t.integer :cost_cents, default: 0
      t.integer :status, default: 0, null: false
      t.text :error_message

      t.timestamps
    end

    add_index :translations, :status
    add_index :translations, :created_at
  end
end
