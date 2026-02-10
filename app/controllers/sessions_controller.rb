class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Вы успешно вошли в систему"
      redirect_to root_path
    else
      flash.now[:alert] = "Неверный email или пароль"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    @current_user = nil
    flash[:notice] = "Вы вышли из системы"
    redirect_to root_path
  end
end
