module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @transcriptions_count = Transcription.count
      @voice_generations_count = VoiceGeneration.count
      @recent_transcriptions = Transcription.recent.limit(5)
      @recent_voice_generations = VoiceGeneration.recent.limit(5)
    end
  end
end
