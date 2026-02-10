module Admin
  class SettingsController < BaseController
    def index
      @settings = Setting::KEYS
    end

    def update
      settings_params.each do |key, value|
        Setting.set(key, value) if Setting::KEYS.key?(key.to_sym)
      end

      flash[:notice] = "Настройки сохранены"
      redirect_to admin_settings_path
    end

    private

    def settings_params
      params.require(:settings).permit(Setting::KEYS.keys)
    end
  end
end
