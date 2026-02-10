class ScheduledPostsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_scheduled_post, only: %i[show destroy]

  def index
    @scheduled_posts = current_user.scheduled_posts.includes(:video_builder, :video_clip).recent.limit(50)
    @upcoming_posts = current_user.scheduled_posts.upcoming.limit(10)
    @social_accounts = current_user.social_accounts.connected
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @scheduled_post.status } }
    end
  end

  def new
    @scheduled_post = current_user.scheduled_posts.build
    @video_builders = current_user.video_builders.completed.recent.limit(20)
    @video_clips = current_user.video_clips.completed.recent.limit(20)
    @social_accounts = current_user.social_accounts.connected
  end

  def create
    @scheduled_post = current_user.scheduled_posts.build(scheduled_post_params)
    @scheduled_post.status = @scheduled_post.scheduled_at.present? ? :scheduled : :pending

    if @scheduled_post.save
      flash[:notice] = @scheduled_post.scheduled? ? "Публикация запланирована" : "Публикация создана"
      redirect_to @scheduled_post
    else
      @video_builders = current_user.video_builders.completed.recent.limit(20)
      @video_clips = current_user.video_clips.completed.recent.limit(20)
      @social_accounts = current_user.social_accounts.connected
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @scheduled_post.destroy
    flash[:notice] = "Публикация удалена"
    redirect_to scheduled_posts_path
  end

  private

  def set_scheduled_post
    @scheduled_post = current_user.scheduled_posts.find(params[:id])
  end

  def scheduled_post_params
    params.require(:scheduled_post).permit(:platform, :video_builder_id, :video_clip_id, :caption, :hashtags, :scheduled_at)
  end
end
