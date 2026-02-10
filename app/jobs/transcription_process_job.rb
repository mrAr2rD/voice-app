class TranscriptionProcessJob < ApplicationJob
  queue_as :transcription

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(transcription_id)
    transcription = Transcription.find(transcription_id)
    return if transcription.completed? || transcription.failed?

    Transcriptions::ProcessService.call(transcription)
  end
end
