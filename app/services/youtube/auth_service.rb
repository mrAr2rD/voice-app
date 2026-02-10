module Youtube
  class AuthService < ApplicationService
    SCOPES = [
      "https://www.googleapis.com/auth/youtube.upload",
      "https://www.googleapis.com/auth/youtube.readonly"
    ].freeze

    def initialize(user, code: nil)
      @user = user
      @code = code
    end

    def call
      if @code.present?
        exchange_code_for_tokens
      else
        failure("Код авторизации не предоставлен")
      end
    rescue StandardError => e
      Rails.logger.error "YouTube AuthService error: #{e.message}"
      failure(e.message)
    end

    def self.authorization_url(redirect_uri)
      params = {
        client_id: credentials[:client_id],
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: SCOPES.join(" "),
        access_type: "offline",
        prompt: "consent"
      }

      "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}"
    end

    def self.credentials
      {
        client_id: Setting.google_client_id || Rails.application.credentials.dig(:google, :client_id),
        client_secret: Setting.google_client_secret || Rails.application.credentials.dig(:google, :client_secret)
      }
    end

    private

    def exchange_code_for_tokens
      conn = Faraday.new(url: "https://oauth2.googleapis.com")
      response = conn.post("/token") do |req|
        req.body = {
          code: @code,
          client_id: self.class.credentials[:client_id],
          client_secret: self.class.credentials[:client_secret],
          redirect_uri: redirect_uri,
          grant_type: "authorization_code"
        }
      end

      unless response.success?
        return failure("Ошибка получения токенов: #{response.body}")
      end

      tokens = JSON.parse(response.body)
      save_credentials(tokens)
    end

    def save_credentials(tokens)
      credential = @user.youtube_credential || @user.build_youtube_credential

      credential.update!(
        access_token_encrypted: tokens["access_token"],
        refresh_token_encrypted: tokens["refresh_token"] || credential.refresh_token_encrypted,
        expires_at: Time.current + tokens["expires_in"].to_i.seconds
      )

      fetch_channel_info(credential)

      success(credential)
    end

    def fetch_channel_info(credential)
      conn = Faraday.new(url: "https://www.googleapis.com/youtube/v3")
      response = conn.get("/channels") do |req|
        req.params["part"] = "snippet"
        req.params["mine"] = true
        req.headers["Authorization"] = "Bearer #{credential.access_token_encrypted}"
      end

      return unless response.success?

      data = JSON.parse(response.body)
      channel = data.dig("items", 0)

      if channel
        credential.update!(
          channel_id: channel["id"],
          channel_name: channel.dig("snippet", "title")
        )
      end
    end

    def redirect_uri
      Rails.application.routes.url_helpers.youtube_callback_url(host: Setting.app_host || "localhost:3000")
    end
  end
end
