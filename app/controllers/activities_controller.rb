class ActivitiesController < ApplicationController
  layout "dashboard"
  before_action :require_login

  def index
    @filter = params[:filter] || "all"

    @activities = case @filter
    when "transcriptions"
      current_user.transcriptions.recent.limit(100).map { |t| ActivityPresenter.new(t) }
    when "voice_generations"
      current_user.voice_generations.recent.limit(100).map { |vg| ActivityPresenter.new(vg) }
    when "translations"
      current_user.translations.recent.limit(100).map { |tr| ActivityPresenter.new(tr) }
    else
      load_all_activities
    end
  end

  private

  def load_all_activities
    transcriptions = current_user.transcriptions.includes(:project).recent.limit(50)
    voice_generations = current_user.voice_generations.includes(:project).recent.limit(50)
    translations = current_user.translations.includes(:project).recent.limit(50)

    all_activities = []
    all_activities.concat(transcriptions.map { |t| ActivityPresenter.new(t) })
    all_activities.concat(voice_generations.map { |vg| ActivityPresenter.new(vg) })
    all_activities.concat(translations.map { |tr| ActivityPresenter.new(tr) })

    all_activities.sort_by(&:created_at).reverse.first(100)
  end
end
