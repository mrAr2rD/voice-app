module Tts
  class GenerationService < ApplicationService
    def initialize(voice_generation)
      @voice_generation = voice_generation
    end

    def call
      @voice_generation.update!(status: :processing)

      client = build_client
      result = client.generate(
        text: @voice_generation.text,
        voice_id: @voice_generation.voice_id
      )

      if result[:success]
        attach_audio(result[:data])
        @voice_generation.update!(status: :completed)
        success(@voice_generation)
      else
        handle_error(result[:error])
        failure(result[:error])
      end
    rescue StandardError => e
      handle_error(e.message)
      failure(e.message)
    end

    private

    def build_client
      case @voice_generation.provider
      when "elevenlabs"
        ElevenlabsClient.new
      when "openai"
        OpenaiClient.new
      else
        raise "Unknown provider: #{@voice_generation.provider}"
      end
    end

    def attach_audio(audio_data)
      filename = "voice_#{@voice_generation.id}_#{Time.current.to_i}.mp3"

      @voice_generation.audio_file.attach(
        io: StringIO.new(audio_data),
        filename: filename,
        content_type: "audio/mpeg"
      )
    end

    def handle_error(message)
      Rails.logger.error "Voice generation error: #{message}"
      @voice_generation.update!(
        status: :failed,
        error_message: message
      )
    end
  end
end
