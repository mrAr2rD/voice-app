class BatchJobsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_batch_job, only: %i[show destroy]

  def index
    @batch_jobs = current_user.batch_jobs.recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: batch_job_json }
    end
  end

  def new
    @batch_job = current_user.batch_jobs.build(job_type: params[:type] || "transcription")
    @projects = current_user.projects.order(:name)
  end

  def create
    @batch_job = current_user.batch_jobs.build(batch_job_params)

    if @batch_job.save
      process_batch_items
      flash[:notice] = "Пакетная обработка запущена"
      redirect_to @batch_job
    else
      @projects = current_user.projects.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @batch_job.destroy
    flash[:notice] = "Пакетная задача удалена"
    redirect_to batch_jobs_path
  end

  private

  def set_batch_job
    @batch_job = current_user.batch_jobs.find(params[:id])
  end

  def batch_job_params
    params.require(:batch_job).permit(:name, :job_type, :settings)
  end

  def batch_job_json
    {
      status: @batch_job.status,
      progress: @batch_job.progress_percentage,
      completed_items: @batch_job.completed_items,
      failed_items: @batch_job.failed_items,
      total_items: @batch_job.total_items
    }
  end

  def process_batch_items
    case @batch_job.job_type
    when "transcription"
      process_transcription_batch
    when "voice_generation"
      process_voice_generation_batch
    when "translation"
      process_translation_batch
    end

    @batch_job.update!(status: :processing)
  end

  def process_transcription_batch
    files = params[:files] || []
    settings = JSON.parse(@batch_job.settings || "{}") rescue {}

    files.each do |file|
      transcription = current_user.transcriptions.create!(
        source_type: detect_source_type(file),
        source_file: file,
        original_filename: file.original_filename,
        project_id: settings["project_id"],
        batch_job: @batch_job
      )
      TranscriptionProcessJob.perform_later(transcription.id)
    end

    @batch_job.update!(total_items: files.count)
  end

  def process_voice_generation_batch
    texts = params[:texts] || []
    settings = JSON.parse(@batch_job.settings || "{}") rescue {}

    texts.each do |text|
      voice_gen = current_user.voice_generations.create!(
        text: text,
        provider: settings["provider"] || "elevenlabs",
        voice_id: settings["voice_id"],
        voice_name: settings["voice_name"],
        project_id: settings["project_id"],
        batch_job: @batch_job
      )
      VoiceGenerationJob.perform_later(voice_gen.id)
    end

    @batch_job.update!(total_items: texts.count)
  end

  def process_translation_batch
    texts = params[:texts] || []
    settings = JSON.parse(@batch_job.settings || "{}") rescue {}

    texts.each do |text|
      translation = current_user.translations.create!(
        source_text: text,
        target_language: settings["target_language"] || "en",
        source_language: settings["source_language"] || "auto",
        model: settings["model"] || "google/gemini-2.0-flash-001",
        project_id: settings["project_id"],
        batch_job: @batch_job
      )
      TranslationJob.perform_later(translation.id)
    end

    @batch_job.update!(total_items: texts.count)
  end

  def detect_source_type(file)
    content_type = file.content_type
    if content_type.start_with?("video/")
      :video_upload
    else
      :audio_upload
    end
  end
end
