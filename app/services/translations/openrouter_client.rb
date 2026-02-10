module Translations
  class OpenrouterClient
    API_URL = "https://openrouter.ai/api/v1/chat/completions".freeze

    def initialize
      @api_key = Setting.openrouter_api_key
      raise "OpenRouter API key not configured" unless @api_key.present?
    end

    def translate(text:, source_language:, target_language:, model:)
      source_lang_name = language_name(source_language)
      target_lang_name = language_name(target_language)

      prompt = build_prompt(text, source_lang_name, target_lang_name)

      response = connection.post do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.headers["Content-Type"] = "application/json"
        req.headers["HTTP-Referer"] = "https://voiceapp.local"
        req.body = {
          model: model,
          messages: [
            { role: "system", content: system_prompt(target_lang_name) },
            { role: "user", content: prompt }
          ],
          temperature: 0.3
        }.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 120
        f.options.open_timeout = 30
      end
    end

    def system_prompt(target_lang)
      <<~PROMPT
        Ты профессиональный переводчик. Переведи текст на #{target_lang}.
        Сохраняй форматирование, абзацы и стиль оригинала.
        Отвечай ТОЛЬКО переводом, без пояснений и комментариев.
      PROMPT
    end

    def build_prompt(text, source_lang, target_lang)
      if source_lang == "Авто"
        "Переведи на #{target_lang}:\n\n#{text}"
      else
        "Переведи с #{source_lang} на #{target_lang}:\n\n#{text}"
      end
    end

    def language_name(code)
      return "Авто" if code == "auto"
      Translation::LANGUAGES.find { |l| l[1] == code }&.first || code
    end

    def handle_response(response)
      if response.success?
        data = JSON.parse(response.body)
        translated_text = data.dig("choices", 0, "message", "content")
        tokens = data.dig("usage", "total_tokens") || 0

        if translated_text.present?
          { success: true, data: { translated_text: translated_text.strip, tokens_used: tokens } }
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
