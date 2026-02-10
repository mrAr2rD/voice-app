class CreateBatchJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :batch_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :job_type, null: false
      t.integer :status, default: 0, null: false
      t.integer :total_items, default: 0
      t.integer :completed_items, default: 0
      t.integer :failed_items, default: 0
      t.text :error_message
      t.text :settings

      t.timestamps
    end

    add_index :batch_jobs, :status
    add_index :batch_jobs, :job_type
    add_index :batch_jobs, :created_at
  end
end
