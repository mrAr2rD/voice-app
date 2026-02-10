class VideoClipsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_video_clip, only: %i[show destroy download]

  def index
    @video_clips = current_user.video_clips
                               .includes(:project, :transcription, output_video_attachment: :blob)
                               .recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @video_clip.status } }
    end
  end

  def new
    @video_clip = current_user.video_clips.build
    @transcriptions = current_user.transcriptions.completed.recent.limit(20)
    @video_builders = current_user.video_builders.completed.recent.limit(20)
    @projects = current_user.projects.order(:name)
  end

  def create
    @video_clip = current_user.video_clips.build(video_clip_params)

    if @video_clip.save
      VideoClipJob.perform_later(@video_clip.id)
      flash[:notice] = "Создание клипа запущено"
      redirect_to @video_clip
    else
      @transcriptions = current_user.transcriptions.completed.recent.limit(20)
      @video_builders = current_user.video_builders.completed.recent.limit(20)
      @projects = current_user.projects.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def auto_detect
    transcription = current_user.transcriptions.find(params[:transcription_id])

    result = Clipping::HighlightDetectorService.call(
      transcription,
      min_duration: params[:min_duration]&.to_i || 15,
      max_duration: params[:max_duration]&.to_i || 60,
      max_clips: params[:max_clips]&.to_i || 5
    )

    if result.success?
      render json: { success: true, clips: result.data }
    else
      render json: { success: false, error: result.error }
    end
  end

  def bulk_create
    clips_data = params[:clips] || []
    transcription = current_user.transcriptions.find(params[:transcription_id])

    created_clips = clips_data.map do |clip_data|
      video_clip = current_user.video_clips.create!(
        transcription: transcription,
        project: transcription.project,
        title: clip_data[:title],
        start_time: clip_data[:start_time],
        end_time: clip_data[:end_time],
        virality_score: clip_data[:virality_score],
        highlight_reason: clip_data[:reason],
        aspect_ratio: params[:aspect_ratio] || "9:16",
        subtitles_enabled: params[:subtitles_enabled] != "false",
        subtitles_style: params[:subtitles_style] || "animated"
      )
      VideoClipJob.perform_later(video_clip.id)
      video_clip
    end

    flash[:notice] = "#{created_clips.size} клипов создано"
    redirect_to video_clips_path
  end

  def destroy
    @video_clip.destroy
    flash[:notice] = "Клип удалён"
    redirect_to video_clips_path
  end

  def download
    unless @video_clip.output_video.attached?
      flash[:alert] = "Видео недоступно"
      return redirect_to @video_clip
    end

    send_data @video_clip.output_video.download,
              filename: "#{@video_clip.display_title.parameterize}.mp4",
              type: "video/mp4",
              disposition: "attachment"
  end

  private

  def set_video_clip
    @video_clip = current_user.video_clips.find(params[:id])
  end

  def video_clip_params
    params.require(:video_clip).permit(
      :title, :start_time, :end_time, :aspect_ratio,
      :subtitles_enabled, :subtitles_style,
      :project_id, :transcription_id, :source_video_builder_id,
      :source_video
    )
  end
end
