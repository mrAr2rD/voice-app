class AddBatchJobToVoiceGenerations < ActiveRecord::Migration[8.1]
  def change
    add_reference :voice_generations, :batch_job, foreign_key: true
  end
end
