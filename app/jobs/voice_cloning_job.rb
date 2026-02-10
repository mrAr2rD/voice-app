class VoiceCloningJob < ApplicationJob
  queue_as :default

  def perform(cloned_voice_id)
    cloned_voice = ClonedVoice.find(cloned_voice_id)
    Tts::VoiceCloningService.call(cloned_voice)
  end
end
