class YoutubeAuthController < ApplicationController
  layout "dashboard"
  before_action :require_login

  def auth
    if current_user.youtube_credential&.connected?
      @credential = current_user.youtube_credential
      render :connected
    else
      redirect_to Youtube::AuthService.authorization_url(youtube_callback_url), allow_other_host: true
    end
  end

  def callback
    code = params[:code]

    if code.blank?
      flash[:alert] = "Авторизация отменена"
      return redirect_to youtube_auth_path
    end

    result = Youtube::AuthService.call(current_user, code: code)

    if result.success?
      flash[:notice] = "YouTube аккаунт подключён: #{result.data.channel_name}"
    else
      flash[:alert] = "Ошибка подключения: #{result.error}"
    end

    redirect_to youtube_auth_path
  end

  def disconnect
    current_user.youtube_credential&.destroy
    flash[:notice] = "YouTube аккаунт отключён"
    redirect_to youtube_auth_path
  end
end
