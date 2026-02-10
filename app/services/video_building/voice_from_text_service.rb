module VideoBuilding
  class VoiceFromTextService < ApplicationService
    MAX_TEXT_LENGTH = 5000

    def initialize(video_builder, text_source:, voice_id: "alloy", provider: :openai)
      @video_builder = video_builder
      @text_source = text_source
      @voice_id = voice_id
      @provider = provider
    end

    def call
      return success(nil) if @text_source.blank?

      text = extract_text
      return success(nil) if text.blank?

      voice_generation = create_voice_generation(text)
      attach_to_video_builder(voice_generation)

      VoiceGenerationJob.perform_later(voice_generation.id)

      success(voice_generation)
    end

    private

    def extract_text
      type, id = @text_source.split("_", 2)
      return nil if id.blank?

      user = @video_builder.user

      case type
      when "transcription"
        user.transcriptions.find_by(id: id)&.full_text
      when "translation"
        user.translations.find_by(id: id)&.translated_text
      end
    end

    def create_voice_generation(text)
      @video_builder.user.voice_generations.create!(
        text: text.truncate(MAX_TEXT_LENGTH),
        voice_id: @voice_id,
        provider: @provider,
        status: :pending
      )
    end

    def attach_to_video_builder(voice_generation)
      @video_builder.audio_sources.create!(
        voice_generation: voice_generation,
        position: @video_builder.audio_sources.count
      )
    end
  end
end
