module Translations
  class TranslateService < ApplicationService
    def initialize(translation)
      @translation = translation
    end

    def call
      @translation.update!(status: :processing)

      result = translate_text
      if result[:success]
        save_result(result[:data])
        @translation.update!(status: :completed)
        success(@translation)
      else
        handle_error(result[:error])
        failure(result[:error])
      end
    rescue StandardError => e
      handle_error(e.message)
      failure(e.message)
    end

    private

    def translate_text
      client = OpenrouterClient.new
      client.translate(
        text: @translation.source_text,
        source_language: @translation.source_language,
        target_language: @translation.target_language,
        model: @translation.model
      )
    end

    def save_result(data)
      @translation.update!(
        translated_text: data[:translated_text],
        tokens_used: data[:tokens_used] || 0,
        cost_cents: calculate_cost(data[:tokens_used] || 0)
      )
    end

    def calculate_cost(tokens)
      # Примерная стоимость: $0.001 за 1000 токенов
      ((tokens.to_f / 1000) * 0.1).round
    end

    def handle_error(message)
      Rails.logger.error "Translation error: #{message}"
      @translation.update!(
        status: :failed,
        error_message: message
      )
    end
  end
end
