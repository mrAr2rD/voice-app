class YoutubeAnalyticsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :require_youtube_connection

  def index
    @period = (params[:period] || 28).to_i
    result = Youtube::AnalyticsService.call(current_user, days: @period)

    if result.success?
      @analytics = result.data
    else
      @error = result.error
    end

    @published_videos = current_user.video_builders
                                    .where.not(youtube_video_id: nil)
                                    .order(published_at: :desc)
                                    .limit(10)
  end

  def show
    video_id = params[:id]
    @period = (params[:period] || 28).to_i

    result = Youtube::AnalyticsService.call(current_user, video_id: video_id, days: @period)

    if result.success?
      @analytics = result.data
    else
      flash[:alert] = result.error
      redirect_to youtube_analytics_path
    end
  end

  private

  def require_youtube_connection
    unless current_user.youtube_credential&.access_token.present?
      flash[:alert] = "Подключите YouTube аккаунт для просмотра аналитики"
      redirect_to profile_path
    end
  end
end
