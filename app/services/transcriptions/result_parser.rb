module Transcriptions
  class ResultParser < ApplicationService
    def initialize(transcription, api_response)
      @transcription = transcription
      @api_response = api_response
    end

    def call
      return failure("Пустой ответ API") unless @api_response.present?

      parse_response
      success(@transcription)
    rescue StandardError => e
      failure("Ошибка парсинга: #{e.message}")
    end

    private

    def parse_response
      @transcription.full_text = @api_response["text"]
      @transcription.language = @api_response["language"]
      @transcription.duration = @api_response["duration"]

      parse_segments(@api_response["segments"]) if @api_response["segments"].present?
    end

    def parse_segments(segments)
      segments.each do |segment|
        @transcription.transcription_segments.build(
          text: segment["text"]&.strip,
          start_time: segment["start"],
          end_time: segment["end"],
          speaker: extract_speaker(segment),
          confidence: calculate_confidence(segment)
        )
      end
    end

    def extract_speaker(segment)
      segment["speaker"] || segment["speaker_id"]
    end

    def calculate_confidence(segment)
      return segment["confidence"] if segment["confidence"]
      return nil unless segment["words"]

      confidences = segment["words"].filter_map { |w| w["confidence"] }
      return nil if confidences.empty?

      (confidences.sum / confidences.size).round(3)
    end
  end
end
