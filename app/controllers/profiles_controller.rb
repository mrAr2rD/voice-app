class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @transcriptions_count = current_user.transcriptions.count
    @voice_generations_count = current_user.voice_generations.count
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
