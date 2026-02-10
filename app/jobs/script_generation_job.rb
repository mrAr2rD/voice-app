class ScriptGenerationJob < ApplicationJob
  queue_as :default

  def perform(script_id)
    script = Script.find(script_id)
    Scripts::GenerationService.call(script)
  end
end
