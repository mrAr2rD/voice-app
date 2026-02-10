class CreateScripts < ActiveRecord::Migration[8.1]
  def change
    create_table :scripts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.string :title
      t.string :script_type, null: false, default: "tutorial"
      t.text :topic, null: false
      t.text :content
      t.integer :status, default: 0, null: false
      t.string :model, default: "google/gemini-2.0-flash-001"
      t.integer :tokens_used, default: 0
      t.text :error_message
      t.string :language, default: "ru"
      t.integer :duration_seconds

      t.timestamps
    end

    add_index :scripts, :status
    add_index :scripts, :script_type
    add_index :scripts, :created_at
  end
end
