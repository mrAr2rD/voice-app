class ProfilesController < ApplicationController
  layout "dashboard"
  before_action :require_login

  def show
    @transcriptions_count = current_user.transcriptions.count
    @voice_generations_count = current_user.voice_generations.count
    @translations_count = current_user.translations.count
    @video_builders_count = current_user.video_builders.count
    @youtube_credential = current_user.youtube_credential
  end

  def edit
  end

  def update
    if current_user.update(user_params)
      flash[:notice] = "Профиль успешно обновлен"
      redirect_to profile_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
