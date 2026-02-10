class AddBatchJobToTranscriptions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transcriptions, :batch_job, foreign_key: true
  end
end
