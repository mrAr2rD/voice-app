module Scripts
  class GenerationService < ApplicationService
    API_URL = "https://openrouter.ai/api/v1/chat/completions".freeze

    def initialize(script)
      @script = script
      @api_key = Setting.openrouter_api_key
    end

    def call
      return failure("OpenRouter API ключ не настроен") unless @api_key.present?

      @script.update!(status: :processing)

      result = generate_script

      if result[:success]
        @script.update!(
          status: :completed,
          content: result[:data][:content],
          tokens_used: result[:data][:tokens_used]
        )
        success(@script)
      else
        @script.update!(status: :failed, error_message: result[:error])
        failure(result[:error])
      end
    rescue StandardError => e
      @script.update!(status: :failed, error_message: e.message)
      failure(e.message)
    end

    private

    def generate_script
      response = connection.post do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.headers["Content-Type"] = "application/json"
        req.headers["HTTP-Referer"] = "https://prodmarket.local"
        req.body = request_body.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    def request_body
      {
        model: @script.model,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.7,
        max_tokens: 4000
      }
    end

    def system_prompt
      language = @script.language == "ru" ? "русском" : "английском"
      duration_guide = duration_word_count

      <<~PROMPT
        Ты опытный сценарист для видеоконтента. Пиши сценарии на #{language} языке.

        Правила:
        1. Пиши живым, разговорным языком
        2. Используй короткие предложения для легкого чтения
        3. Добавляй паузы и акценты через форматирование
        4. Включай хуки и призывы к действию
        5. Целевой объем: примерно #{duration_guide} слов

        Формат сценария:
        - [INTRO] - вступление с хуком
        - [MAIN] - основная часть
        - [CTA] - призыв к действию
        - [OUTRO] - завершение

        Отвечай ТОЛЬКО текстом сценария, без пояснений.
      PROMPT
    end

    def user_prompt
      type_instruction = case @script.script_type
      when "tutorial"
                           "Создай обучающий сценарий с пошаговыми инструкциями"
      when "review"
                           "Создай сценарий обзора с плюсами, минусами и вердиктом"
      when "sales"
                           "Создай продающий сценарий с проблемой, решением и CTA"
      when "educational"
                           "Создай образовательный сценарий с фактами и примерами"
      when "entertainment"
                           "Создай развлекательный сценарий с юмором и энергией"
      when "news"
                           "Создай новостной сценарий с фактами и комментариями"
      when "interview"
                           "Создай сценарий интервью с вопросами и переходами"
      when "podcast"
                           "Создай сценарий подкаста с вступлением, темами и завершением"
      else
                           "Создай сценарий для видео"
      end

      "#{type_instruction} на тему:\n\n#{@script.topic}"
    end

    def duration_word_count
      case @script.duration_seconds
      when 0..60 then "75-100"
      when 61..180 then "200-300"
      when 181..420 then "500-700"
      else "1000-1500"
      end
    end

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 180
        f.options.open_timeout = 30
      end
    end

    def handle_response(response)
      if response.success?
        data = JSON.parse(response.body)
        content = data.dig("choices", 0, "message", "content")
        tokens = data.dig("usage", "total_tokens") || 0

        if content.present?
          { success: true, data: { content: content.strip, tokens_used: tokens } }
        else
          { success: false, error: "Empty response from API" }
        end
      else
        error_body = JSON.parse(response.body) rescue response.body
        error_message = error_body.is_a?(Hash) ? error_body.dig("error", "message") : error_body
        { success: false, error: "API error (#{response.status}): #{error_message}" }
      end
    end
  end
end
