class VideoBuildersController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_video_builder, only: %i[show edit update destroy download publish generate_thumbnail generate_metadata]

  def index
    @video_builders = current_user.video_builders.recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @video_builder.status, progress: @video_builder.progress } }
    end
  end

  def new
    @video_builder = current_user.video_builders.build
    load_form_data
  end

  def create
    @video_builder = current_user.video_builders.build(video_builder_params)

    if @video_builder.save
      attach_audio_sources
      create_voice_from_text_source if params[:video_builder][:text_source].present?
      VideoBuilderProcessJob.perform_later(@video_builder.id)
      flash[:notice] = "Обработка видео запущена"
      redirect_to @video_builder
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @video_builder.update(video_builder_params)
      flash[:notice] = "Видео-билдер обновлён"
      redirect_to @video_builder
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @video_builder.destroy
    flash[:notice] = "Видео-билдер удалён"
    redirect_to video_builders_path
  end

  def download
    unless @video_builder.output_video.attached?
      flash[:alert] = "Видео ещё не готово"
      return redirect_to @video_builder
    end

    redirect_to rails_blob_path(@video_builder.output_video, disposition: "attachment")
  end

  def publish
    unless @video_builder.can_publish?
      flash[:alert] = "Невозможно опубликовать видео"
      return redirect_to @video_builder
    end

    unless current_user.youtube_credential&.connected?
      flash[:alert] = "Сначала подключите YouTube аккаунт"
      return redirect_to youtube_auth_path
    end

    @video_builder.update!(youtube_status: "publishing")
    YoutubeUploadJob.perform_later(@video_builder.id)
    flash[:notice] = "Публикация на YouTube запущена"
    redirect_to @video_builder
  end

  def generate_thumbnail
    prompt = params[:prompt]
    result = Ai::ThumbnailGeneratorService.call(@video_builder, prompt: prompt)

    if result.success?
      flash[:notice] = "Обложка сгенерирована"
    else
      flash[:alert] = "Ошибка генерации: #{result.error}"
    end

    redirect_to @video_builder
  end

  def generate_metadata
    context = params[:context]
    result = Ai::MetadataGeneratorService.call(@video_builder, context: context)

    if result.success?
      flash[:notice] = "Метаданные сгенерированы"
    else
      flash[:alert] = "Ошибка генерации: #{result.error}"
    end

    redirect_to @video_builder
  end

  private

  def set_video_builder
    @video_builder = current_user.video_builders.find(params[:id])
  end

  def video_builder_params
    params.require(:video_builder).permit(
      :title, :description, :project_id, :video_mode,
      :subtitles_enabled, :subtitles_style, :subtitles_position, :subtitles_font_size,
      :source_video, :source_audio, :subtitles_file, :thumbnail,
      :youtube_title, :youtube_description, :youtube_tags,
      background_videos: []
    )
  end

  def attach_audio_sources
    voice_generation_ids = params[:video_builder][:voice_generation_ids]
    return unless voice_generation_ids.present?

    voice_generation_ids.reject(&:blank?).each_with_index do |vg_id, index|
      @video_builder.audio_sources.create!(
        voice_generation_id: vg_id,
        position: index
      )
    end
  end

  def load_form_data
    @projects = current_user.projects.recent
    @voice_generations = current_user.voice_generations.completed.recent.limit(50)
    @transcriptions = current_user.transcriptions.completed.recent.limit(20)
    @translations = current_user.translations.completed.recent.limit(20)
  end

  def create_voice_from_text_source
    text_source = params[:video_builder][:text_source]
    return if text_source.blank?

    type, id = text_source.split("_", 2)
    text = case type
           when "transcription"
             current_user.transcriptions.find_by(id: id)&.full_text
           when "translation"
             current_user.translations.find_by(id: id)&.translated_text
           end

    return if text.blank?

    voice_generation = current_user.voice_generations.create!(
      text: text.truncate(5000),
      voice_id: "alloy",
      provider: :openai,
      status: :pending
    )

    VoiceGenerationJob.perform_later(voice_generation.id)

    @video_builder.audio_sources.create!(
      voice_generation: voice_generation,
      position: @video_builder.audio_sources.count
    )
  end
end
