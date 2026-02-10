class AddUsageStatsToTranscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :transcriptions, :audio_duration_seconds, :float, default: 0
    add_column :transcriptions, :tokens_used, :integer, default: 0
    add_column :transcriptions, :cost_cents, :integer, default: 0
  end
end
