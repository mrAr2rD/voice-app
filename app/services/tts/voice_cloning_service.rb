module Tts
  class VoiceCloningService < ApplicationService
    def initialize(cloned_voice)
      @cloned_voice = cloned_voice
    end

    def call
      return failure("Нет аудио образцов для клонирования") unless @cloned_voice.audio_samples.attached?

      @cloned_voice.update!(status: :processing)

      files = prepare_files
      return failure("Не удалось подготовить аудио файлы") if files.empty?

      result = create_voice_clone(files)

      if result[:success]
        @cloned_voice.update!(
          status: :completed,
          elevenlabs_voice_id: result[:data]["voice_id"]
        )
        success(@cloned_voice)
      else
        @cloned_voice.update!(
          status: :failed,
          error_message: result[:error]
        )
        failure(result[:error])
      end
    rescue StandardError => e
      @cloned_voice.update!(status: :failed, error_message: e.message)
      failure(e.message)
    end

    private

    def prepare_files
      @cloned_voice.audio_samples.map do |sample|
        {
          io: StringIO.new(sample.download),
          content_type: sample.content_type,
          filename: sample.filename.to_s
        }
      end
    end

    def create_voice_clone(files)
      client = ElevenlabsClient.new
      client.clone_voice(
        name: @cloned_voice.name,
        description: @cloned_voice.description.to_s,
        files: files,
        labels: parse_labels
      )
    end

    def parse_labels
      labels = {}
      @cloned_voice.labels_array.each_with_index do |label, index|
        labels["label_#{index}"] = label
      end
      labels
    end
  end
end
