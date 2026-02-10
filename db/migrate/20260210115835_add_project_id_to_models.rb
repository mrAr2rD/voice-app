class AddProjectIdToModels < ActiveRecord::Migration[8.1]
  def change
    add_reference :transcriptions, :project, foreign_key: true
    add_reference :translations, :project, foreign_key: true
    add_reference :voice_generations, :project, foreign_key: true
  end
end
