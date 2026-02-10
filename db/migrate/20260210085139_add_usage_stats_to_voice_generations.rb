class AddUsageStatsToVoiceGenerations < ActiveRecord::Migration[8.1]
  def change
    add_column :voice_generations, :characters_count, :integer, default: 0
    add_column :voice_generations, :cost_cents, :integer, default: 0
  end
end
