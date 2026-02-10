module Ai
  class MetadataGeneratorService < ApplicationService
    def initialize(video_builder, context: nil)
      @video_builder = video_builder
      @context = context
    end

    def call
      return failure("OpenAI API ключ не настроен") unless api_key.present?

      generate_metadata
    rescue StandardError => e
      Rails.logger.error "AI MetadataGeneratorService error: #{e.message}"
      failure(e.message)
    end

    private

    def generate_metadata
      prompt = build_prompt

      conn = Faraday.new(url: "https://api.openai.com") do |f|
        f.options.timeout = 60
      end

      response = conn.post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: prompt }
          ],
          temperature: 0.7,
          response_format: { type: "json_object" }
        }.to_json
      end

      unless response.success?
        error_data = JSON.parse(response.body) rescue {}
        error_message = error_data.dig("error", "message") || "Неизвестная ошибка"
        return failure("GPT ошибка: #{error_message}")
      end

      data = JSON.parse(response.body)
      content = data.dig("choices", 0, "message", "content")

      return failure("Не удалось получить ответ от GPT") unless content.present?

      metadata = JSON.parse(content)
      update_video_builder(metadata)
    end

    def system_prompt
      <<~PROMPT
        Ты — эксперт по YouTube SEO и созданию вирусного контента.
        Твоя задача — генерировать привлекательные заголовки, описания и теги для YouTube видео.

        Требования:
        - Заголовок: до 100 символов, цепляющий, с эмодзи если уместно
        - Описание: 2-3 абзаца, SEO-оптимизированное, с хештегами в конце
        - Теги: 10-15 релевантных тегов через запятую

        Всегда отвечай на языке контента (если контент на русском — отвечай на русском).

        Формат ответа (JSON):
        {
          "title": "Заголовок видео",
          "description": "Полное описание\\n\\n#хештег1 #хештег2",
          "tags": "тег1, тег2, тег3"
        }
      PROMPT
    end

    def build_prompt
      parts = []

      parts << "Название проекта: #{@video_builder.title}" if @video_builder.title.present?
      parts << "Описание: #{@video_builder.description}" if @video_builder.description.present?

      if @context.present?
        parts << "Дополнительный контекст: #{@context}"
      end

      if @video_builder.audio_sources.any?
        texts = @video_builder.audio_sources.includes(:voice_generation).filter_map do |source|
          source.voice_generation&.text&.truncate(500)
        end
        parts << "Текст озвучки: #{texts.join(' ')}" if texts.any?
      end

      if parts.empty?
        parts << "Создай универсальные метаданные для видео"
      end

      parts.join("\n\n")
    end

    def update_video_builder(metadata)
      @video_builder.update!(
        youtube_title: metadata["title"],
        youtube_description: metadata["description"],
        youtube_tags: metadata["tags"]
      )

      success(metadata)
    end

    def api_key
      Setting.openai_api_key || Rails.application.credentials.dig(:openai, :api_key)
    end
  end
end
