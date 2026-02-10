class HomeController < ApplicationController
  layout :choose_layout

  def index
    if logged_in?
      @recent_transcriptions = current_user.transcriptions.recent.limit(5)
      @recent_voice_generations = current_user.voice_generations.recent.limit(5)
      @recent_translations = current_user.translations.recent.limit(5)
    end
  end

  private

  def choose_layout
    logged_in? ? "dashboard" : "application"
  end
end
