module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @transcriptions_count = Transcription.count
      @voice_generations_count = VoiceGeneration.count
      @translations_count = Translation.count
      @recent_transcriptions = Transcription.recent.limit(5)
      @recent_voice_generations = VoiceGeneration.recent.limit(5)

      # Статистика использования
      @transcription_stats = {
        total_duration: Transcription.sum(:audio_duration_seconds) || 0,
        total_tokens: Transcription.sum(:tokens_used) || 0,
        total_cost: Transcription.sum(:cost_cents) || 0
      }

      @voice_generation_stats = {
        total_characters: VoiceGeneration.sum(:characters_count) || 0,
        total_cost: VoiceGeneration.sum(:cost_cents) || 0,
        by_provider: {
          openai: VoiceGeneration.where(provider: :openai).sum(:cost_cents) || 0,
          elevenlabs: VoiceGeneration.where(provider: :elevenlabs).sum(:cost_cents) || 0
        }
      }

      @translation_stats = {
        total_tokens: Translation.sum(:tokens_used) || 0,
        total_cost: Translation.sum(:cost_cents) || 0
      }

      @total_cost = @transcription_stats[:total_cost] + @voice_generation_stats[:total_cost] + @translation_stats[:total_cost]
    end
  end
end
