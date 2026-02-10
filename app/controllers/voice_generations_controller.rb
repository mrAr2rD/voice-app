class VoiceGenerationsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :check_voice_generation_enabled, only: %i[new create]
  before_action :set_voice_generation, only: %i[show destroy download]

  def index
    @voice_generations = current_user.voice_generations
                                     .includes(:project, audio_file_attachment: :blob)
                                     .recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @voice_generation.status } }
    end
  end

  def new
    @voice_generation = current_user.voice_generations.build
    @elevenlabs_voices = fetch_elevenlabs_voices
    @cloned_voices = current_user.cloned_voices.ready
    @openai_voices = Tts::OpenaiClient::VOICES
    @projects = current_user.projects.order(:name)
  end

  def create
    @voice_generation = current_user.voice_generations.build(voice_generation_params)

    if @voice_generation.save
      VoiceGenerationJob.perform_later(@voice_generation.id)
      flash[:notice] = "Генерация голоса запущена"
      redirect_to @voice_generation
    else
      @elevenlabs_voices = fetch_elevenlabs_voices
      @cloned_voices = current_user.cloned_voices.ready
      @openai_voices = Tts::OpenaiClient::VOICES
      @projects = current_user.projects.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @voice_generation.destroy
    flash[:notice] = "Запись удалена"
    redirect_to voice_generations_path
  end

  def download
    unless @voice_generation.audio_file.attached?
      flash[:alert] = "Аудиофайл недоступен"
      return redirect_to @voice_generation
    end

    send_data @voice_generation.audio_file.download,
              filename: "voice_#{@voice_generation.id}.mp3",
              type: "audio/mpeg",
              disposition: "attachment"
  end

  def voices
    provider = params[:provider] || "elevenlabs"

    voices = case provider
    when "elevenlabs"
               fetch_elevenlabs_voices
    when "openai"
               Tts::OpenaiClient::VOICES
    else
               []
    end

    render json: voices
  end

  private

  def set_voice_generation
    @voice_generation = current_user.voice_generations.find(params[:id])
  end

  def voice_generation_params
    params.require(:voice_generation).permit(:text, :provider, :voice_id, :voice_name, :project_id)
  end

  def fetch_elevenlabs_voices
    client = Tts::ElevenlabsClient.new
    result = client.voices
    result[:data] || Tts::ElevenlabsClient::DEFAULT_VOICES
  rescue StandardError
    Tts::ElevenlabsClient::DEFAULT_VOICES
  end

  def check_voice_generation_enabled
    unless Setting.voice_generation_enabled?
      flash[:alert] = "Сервис озвучки временно отключён"
      redirect_to voice_generations_path
    end
  end
end
