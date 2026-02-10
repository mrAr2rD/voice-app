class ActivityPresenter
  attr_reader :record

  delegate :id, :created_at, :status, to: :record

  def initialize(record)
    @record = record
  end

  def type
    record.class.name.underscore
  end

  def type_label
    case type
    when "transcription"
      "Транскрибация"
    when "voice_generation"
      "Озвучка"
    when "translation"
      "Перевод"
    end
  end

  def title
    case type
    when "transcription"
      record.display_title
    when "voice_generation"
      record.text_preview
    when "translation"
      record.text_preview(60)
    end
  end

  def subtitle
    case type
    when "transcription"
      parts = []
      parts << source_type_label
      parts << record.duration_formatted if record.duration.present?
      parts.join(" · ")
    when "voice_generation"
      record.provider_display_name
    when "translation"
      "#{record.source_language_name} → #{record.target_language_name}"
    end
  end

  def source_type_label
    return nil unless type == "transcription"

    case record.source_type
    when "audio_upload" then "Аудио"
    when "video_upload" then "Видео"
    when "youtube_url" then "YouTube"
    end
  end

  def path
    case type
    when "transcription"
      Rails.application.routes.url_helpers.transcription_path(record)
    when "voice_generation"
      Rails.application.routes.url_helpers.voice_generation_path(record)
    when "translation"
      Rails.application.routes.url_helpers.translation_path(record)
    end
  end

  def icon_color
    case type
    when "transcription"
      "var(--color-neon-blue)"
    when "voice_generation"
      "var(--color-neon-purple)"
    when "translation"
      "var(--color-neon-green)"
    end
  end

  def icon_bg
    case type
    when "transcription"
      "rgba(0, 212, 255, 0.1)"
    when "voice_generation"
      "rgba(168, 85, 247, 0.1)"
    when "translation"
      "rgba(34, 211, 187, 0.1)"
    end
  end

  def icon_svg
    case type
    when "transcription"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>'
    when "voice_generation"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"/>'
    when "translation"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/>'
    end
  end

  def status_partial
    case type
    when "transcription"
      "transcriptions/status_badge"
    when "voice_generation"
      "voice_generations/status_badge"
    when "translation"
      "translations/status_badge"
    end
  end

  def status_locals
    case type
    when "transcription"
      { transcription: record }
    when "voice_generation"
      { voice_generation: record }
    when "translation"
      { translation: record }
    end
  end

  def completed?
    record.completed?
  end

  def failed?
    record.failed?
  end

  def in_progress?
    record.respond_to?(:in_progress?) ? record.in_progress? : false
  end
end
