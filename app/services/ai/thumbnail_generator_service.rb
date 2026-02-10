module Ai
  class ThumbnailGeneratorService < ApplicationService
    IMAGE_SIZE = "1792x1024"

    def initialize(video_builder, prompt: nil)
      @video_builder = video_builder
      @prompt = prompt
    end

    def call
      return failure("OpenAI API ключ не настроен") unless api_key.present?

      generate_thumbnail
    rescue StandardError => e
      Rails.logger.error "AI ThumbnailGeneratorService error: #{e.message}"
      failure(e.message)
    end

    private

    def generate_thumbnail
      enhanced_prompt = build_prompt

      conn = Faraday.new(url: "https://api.openai.com") do |f|
        f.options.timeout = 120
      end

      response = conn.post("/v1/images/generations") do |req|
        req.headers["Authorization"] = "Bearer #{api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: "dall-e-3",
          prompt: enhanced_prompt,
          n: 1,
          size: IMAGE_SIZE,
          quality: "standard",
          response_format: "url"
        }.to_json
      end

      unless response.success?
        error_data = JSON.parse(response.body) rescue {}
        error_message = error_data.dig("error", "message") || "Неизвестная ошибка"
        return failure("DALL-E ошибка: #{error_message}")
      end

      data = JSON.parse(response.body)
      image_url = data.dig("data", 0, "url")

      return failure("Не удалось получить URL изображения") unless image_url.present?

      attach_image(image_url)
    end

    def build_prompt
      base_prompt = @prompt.presence || default_prompt

      "Create a YouTube video thumbnail: #{base_prompt}. " \
      "Style: eye-catching, professional, vibrant colors, high contrast. " \
      "No text or words on the image. " \
      "Aspect ratio: 16:9, optimized for YouTube thumbnails."
    end

    def default_prompt
      if @video_builder.title.present?
        "Based on the title: #{@video_builder.title}"
      elsif @video_builder.description.present?
        "Based on: #{@video_builder.description.truncate(200)}"
      else
        "Abstract professional thumbnail with modern design"
      end
    end

    def attach_image(image_url)
      image_response = Faraday.get(image_url)

      unless image_response.success?
        return failure("Не удалось скачать сгенерированное изображение")
      end

      filename = "thumbnail_#{@video_builder.id}_#{Time.current.to_i}.png"

      @video_builder.thumbnail.attach(
        io: StringIO.new(image_response.body),
        filename: filename,
        content_type: "image/png"
      )

      success(@video_builder)
    end

    def api_key
      Setting.openai_api_key || Rails.application.credentials.dig(:openai, :api_key)
    end
  end
end
