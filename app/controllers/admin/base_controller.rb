module Admin
  class BaseController < ApplicationController
    before_action :require_login
    before_action :require_admin

    layout "admin"

    private

    def require_admin
      unless current_user&.admin?
        flash[:alert] = "Доступ запрещён. Требуются права администратора."
        redirect_to root_path
      end
    end
  end
end
