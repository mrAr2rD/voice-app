class TranscriptionsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :check_transcription_enabled, only: %i[new create]
  before_action :set_transcription, only: %i[show destroy retry download]

  def index
    @transcriptions = current_user.transcriptions.recent.limit(50)
  end

  def show
    @segments = @transcription.transcription_segments.ordered

    respond_to do |format|
      format.html
      format.json { render json: { status: @transcription.status, progress: @transcription.progress } }
    end
  end

  def new
    @transcription = current_user.transcriptions.build
  end

  def create
    @transcription = current_user.transcriptions.build(transcription_params)

    determine_source_type

    if @transcription.save
      TranscriptionProcessJob.perform_later(@transcription.id)
      flash[:notice] = "Транскрибация запущена"
      redirect_to @transcription
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @transcription.destroy
    flash[:notice] = "Транскрибация удалена"
    redirect_to transcriptions_path
  end

  def retry
    return redirect_to @transcription, alert: "Нельзя перезапустить" unless @transcription.failed?

    @transcription.update!(status: :pending, error_message: nil)
    TranscriptionProcessJob.perform_later(@transcription.id)
    flash[:notice] = "Транскрибация перезапущена"
    redirect_to @transcription
  end

  def download
    format = params[:format] || "txt"
    result = Transcriptions::ExportService.call(@transcription, format)

    if result.success?
      send_data result.data[:content],
                filename: result.data[:filename],
                type: result.data[:content_type],
                disposition: "attachment"
    else
      flash[:alert] = result.error
      redirect_to @transcription
    end
  end

  private

  def set_transcription
    @transcription = current_user.transcriptions.find(params[:id])
  end

  def transcription_params
    params.require(:transcription).permit(:title, :youtube_url, :source_file, :language)
  end

  def determine_source_type
    if @transcription.youtube_url.present?
      @transcription.source_type = :youtube_url
    elsif @transcription.source_file.attached?
      content_type = @transcription.source_file.content_type
      @transcription.source_type = content_type.start_with?("video/") ? :video_upload : :audio_upload
      @transcription.original_filename = @transcription.source_file.filename.to_s
    end
  end

  def check_transcription_enabled
    unless Setting.transcription_enabled?
      flash[:alert] = "Сервис транскрибации временно отключён"
      redirect_to transcriptions_path
    end
  end
end
