class AddBatchJobToTranslations < ActiveRecord::Migration[8.1]
  def change
    add_reference :translations, :batch_job, foreign_key: true
  end
end
