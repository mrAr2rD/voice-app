class VoiceGenerationJob < ApplicationJob
  queue_as :voice_generation

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(voice_generation_id)
    voice_generation = VoiceGeneration.find(voice_generation_id)
    return if voice_generation.completed? || voice_generation.failed?

    Tts::GenerationService.call(voice_generation)
  end
end
