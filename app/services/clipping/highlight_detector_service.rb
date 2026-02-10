module Clipping
  class HighlightDetectorService < ApplicationService
    API_URL = "https://openrouter.ai/api/v1/chat/completions".freeze

    def initialize(transcription, options = {})
      @transcription = transcription
      @min_duration = options[:min_duration] || 15
      @max_duration = options[:max_duration] || 60
      @max_clips = options[:max_clips] || 5
      @api_key = Setting.openrouter_api_key
    end

    def call
      return failure("Транскрибация не завершена") unless @transcription.completed?
      return failure("Нет сегментов") if @transcription.transcription_segments.empty?
      return failure("OpenRouter API ключ не настроен") unless @api_key.present?

      segments_text = build_segments_text
      result = analyze_with_ai(segments_text)

      if result[:success]
        success(result[:data])
      else
        fallback_detection
      end
    end

    private

    def build_segments_text
      @transcription.transcription_segments.order(:start_time).map do |seg|
        "[#{format_time(seg.start_time)}-#{format_time(seg.end_time)}] #{seg.text}"
      end.join("\n")
    end

    def analyze_with_ai(segments_text)
      response = connection.post do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.headers["Content-Type"] = "application/json"
        req.headers["HTTP-Referer"] = "https://prodmarket.local"
        req.body = {
          model: "google/gemini-2.5-flash-lite",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: segments_text }
          ],
          temperature: 0.3
        }.to_json
      end

      parse_ai_response(response)
    rescue StandardError => e
      { success: false, error: e.message }
    end

    def system_prompt
      <<~PROMPT
        Ты эксперт по вирусному контенту для TikTok/Reels/Shorts.

        Проанализируй транскрипт видео и найди #{@max_clips} самых интересных моментов для коротких клипов.

        Критерии выбора:
        1. Эмоциональные моменты (смех, удивление, споры)
        2. Сильные утверждения или цитаты
        3. Полезные советы или лайфхаки
        4. Неожиданные повороты
        5. Интригующие вопросы

        Длительность каждого клипа: #{@min_duration}-#{@max_duration} секунд.

        Отвечай ТОЛЬКО в JSON формате:
        {
          "clips": [
            {
              "start_time": 45.5,
              "end_time": 75.2,
              "title": "Короткое название клипа",
              "reason": "Почему этот момент вирусный",
              "virality_score": 8.5
            }
          ]
        }
      PROMPT
    end

    def parse_ai_response(response)
      return { success: false, error: "API error" } unless response.success?

      data = JSON.parse(response.body)
      content = data.dig("choices", 0, "message", "content")

      json_match = content.match(/\{.*\}/m)
      return { success: false, error: "No JSON in response" } unless json_match

      clips_data = JSON.parse(json_match[0])
      clips = clips_data["clips"] || []

      { success: true, data: clips.map { |c| normalize_clip(c) } }
    rescue JSON::ParserError
      { success: false, error: "Invalid JSON response" }
    end

    def normalize_clip(clip)
      {
        start_time: clip["start_time"].to_f,
        end_time: clip["end_time"].to_f,
        title: clip["title"],
        reason: clip["reason"],
        virality_score: clip["virality_score"].to_f
      }
    end

    def fallback_detection
      segments = @transcription.transcription_segments.order(:start_time)
      return failure("Нет сегментов") if segments.empty?

      clips = []
      current_start = segments.first.start_time
      total_duration = segments.last.end_time

      while current_start < total_duration && clips.size < @max_clips
        clip_end = [ current_start + @max_duration, total_duration ].min

        clips << {
          start_time: current_start,
          end_time: clip_end,
          title: "Клип #{clips.size + 1}",
          reason: "Автоматически выбранный фрагмент",
          virality_score: 5.0
        }

        current_start = clip_end + 10
      end

      success(clips)
    end

    def format_time(seconds)
      minutes = (seconds / 60).floor
      secs = (seconds % 60).floor
      format("%d:%02d", minutes, secs)
    end

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 60
        f.options.open_timeout = 30
      end
    end
  end
end
