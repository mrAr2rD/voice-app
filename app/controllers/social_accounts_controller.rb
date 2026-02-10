class SocialAccountsController < ApplicationController
  layout "dashboard"
  before_action :require_login

  def index
    @social_accounts = current_user.social_accounts
  end

  def destroy
    account = current_user.social_accounts.find(params[:id])
    account.destroy
    flash[:notice] = "Аккаунт #{account.platform_name} отключён"
    redirect_to social_accounts_path
  end

  def auth
    platform = params[:platform]

    case platform
    when "tiktok"
      redirect_to tiktok_auth_url, allow_other_host: true
    when "instagram"
      redirect_to instagram_auth_url, allow_other_host: true
    when "vk"
      redirect_to vk_auth_url, allow_other_host: true
    else
      flash[:alert] = "Неизвестная платформа"
      redirect_to social_accounts_path
    end
  end

  def callback
    platform = params[:platform]
    code = params[:code]

    unless code.present?
      flash[:alert] = "Авторизация отменена"
      return redirect_to social_accounts_path
    end

    result = exchange_code_for_token(platform, code)

    if result[:success]
      account = current_user.social_accounts.find_or_initialize_by(platform: platform)
      account.assign_attributes(
        access_token: result[:access_token],
        refresh_token: result[:refresh_token],
        expires_at: result[:expires_at],
        account_id: result[:account_id],
        account_name: result[:account_name],
        status: :active
      )
      account.save!

      flash[:notice] = "#{account.platform_name} подключён"
    else
      flash[:alert] = result[:error] || "Ошибка авторизации"
    end

    redirect_to social_accounts_path
  end

  private

  def tiktok_auth_url
    client_key = Setting.tiktok_client_key
    redirect_uri = social_callback_url(platform: "tiktok")

    "https://www.tiktok.com/v2/auth/authorize?" + {
      client_key: client_key,
      scope: "user.info.basic,video.publish",
      response_type: "code",
      redirect_uri: redirect_uri
    }.to_query
  end

  def instagram_auth_url
    client_id = Setting.instagram_client_id
    redirect_uri = social_callback_url(platform: "instagram")

    "https://api.instagram.com/oauth/authorize?" + {
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: "user_profile,user_media",
      response_type: "code"
    }.to_query
  end

  def vk_auth_url
    client_id = Setting.vk_client_id
    redirect_uri = social_callback_url(platform: "vk")

    "https://oauth.vk.com/authorize?" + {
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: "video,wall,offline",
      response_type: "code",
      v: "5.131"
    }.to_query
  end

  def exchange_code_for_token(platform, code)
    { success: false, error: "Интеграция с #{platform} в разработке" }
  end
end
