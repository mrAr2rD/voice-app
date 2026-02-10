module Transcriptions
  class ExportService < ApplicationService
    FORMATS = %w[txt srt json].freeze

    def initialize(transcription, format)
      @transcription = transcription
      @format = format.to_s.downcase
    end

    def call
      return failure("Неподдерживаемый формат") unless FORMATS.include?(@format)
      return failure("Транскрибация не завершена") unless @transcription.completed?

      content = send("export_to_#{@format}")
      success({
        content: content,
        filename: generate_filename,
        content_type: content_type
      })
    rescue StandardError => e
      failure("Ошибка экспорта: #{e.message}")
    end

    private

    def export_to_txt
      lines = []
      lines << @transcription.display_title
      lines << "=" * 40
      lines << ""

      if @transcription.transcription_segments.any?
        @transcription.transcription_segments.ordered.each do |segment|
          timestamp = "[#{segment.start_time_formatted} - #{segment.end_time_formatted}]"
          speaker = segment.speaker.present? ? " #{segment.speaker}:" : ""
          lines << "#{timestamp}#{speaker}"
          lines << segment.text
          lines << ""
        end
      else
        lines << @transcription.full_text
      end

      lines.join("\n")
    end

    def export_to_srt
      lines = []

      @transcription.transcription_segments.ordered.each_with_index do |segment, index|
        lines << (index + 1).to_s
        lines << "#{segment.srt_timestamp(segment.start_time)} --> #{segment.srt_timestamp(segment.end_time)}"
        speaker_prefix = segment.speaker.present? ? "[#{segment.speaker}] " : ""
        lines << "#{speaker_prefix}#{segment.text}"
        lines << ""
      end

      lines.join("\n")
    end

    def export_to_json
      {
        title: @transcription.display_title,
        duration: @transcription.duration,
        language: @transcription.language,
        full_text: @transcription.full_text,
        segments: @transcription.transcription_segments.ordered.map do |segment|
          {
            text: segment.text,
            start_time: segment.start_time,
            end_time: segment.end_time,
            speaker: segment.speaker,
            confidence: segment.confidence
          }
        end
      }.to_json
    end

    def generate_filename
      base_name = @transcription.display_title.parameterize.presence || "transcription_#{@transcription.id}"
      "#{base_name}.#{@format}"
    end

    def content_type
      case @format
      when "txt" then "text/plain"
      when "srt" then "text/srt"
      when "json" then "application/json"
      end
    end
  end
end
