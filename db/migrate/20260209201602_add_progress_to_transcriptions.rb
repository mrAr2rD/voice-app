class AddProgressToTranscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :transcriptions, :progress, :integer, default: 0
  end
end
