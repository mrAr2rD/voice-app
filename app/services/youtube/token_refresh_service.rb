module Youtube
  class TokenRefreshService < ApplicationService
    def initialize(credential)
      @credential = credential
    end

    def call
      return success(@credential) unless @credential.needs_refresh?
      return failure("Нет refresh token") unless @credential.refresh_token_encrypted.present?

      refresh_token
    rescue StandardError => e
      Rails.logger.error "YouTube TokenRefreshService error: #{e.message}"
      failure(e.message)
    end

    private

    def refresh_token
      conn = Faraday.new(url: "https://oauth2.googleapis.com")
      response = conn.post("/token") do |req|
        req.body = {
          client_id: AuthService.credentials[:client_id],
          client_secret: AuthService.credentials[:client_secret],
          refresh_token: @credential.refresh_token_encrypted,
          grant_type: "refresh_token"
        }
      end

      unless response.success?
        return failure("Ошибка обновления токена: #{response.body}")
      end

      tokens = JSON.parse(response.body)

      @credential.update!(
        access_token_encrypted: tokens["access_token"],
        expires_at: Time.current + tokens["expires_in"].to_i.seconds
      )

      success(@credential)
    end
  end
end
