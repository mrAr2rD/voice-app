class HomeController < ApplicationController
  def index
    if logged_in?
      @recent_transcriptions = current_user.transcriptions.recent.limit(5)
      @recent_voice_generations = current_user.voice_generations.recent.limit(5)
    end
  end
end
