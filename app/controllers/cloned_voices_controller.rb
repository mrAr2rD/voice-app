class ClonedVoicesController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :check_elevenlabs_configured
  before_action :set_cloned_voice, only: %i[show destroy]

  def index
    @cloned_voices = current_user.cloned_voices.recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @cloned_voice.status } }
    end
  end

  def new
    @cloned_voice = current_user.cloned_voices.build
  end

  def create
    @cloned_voice = current_user.cloned_voices.build(cloned_voice_params)

    if @cloned_voice.save
      VoiceCloningJob.perform_later(@cloned_voice.id)
      flash[:notice] = "Клонирование голоса запущено"
      redirect_to @cloned_voice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @cloned_voice.elevenlabs_voice_id.present?
      begin
        client = Tts::ElevenlabsClient.new
        client.delete_voice(voice_id: @cloned_voice.elevenlabs_voice_id)
      rescue StandardError => e
        Rails.logger.warn("Failed to delete voice from ElevenLabs: #{e.message}")
      end
    end

    @cloned_voice.destroy
    flash[:notice] = "Клонированный голос удалён"
    redirect_to cloned_voices_path
  end

  private

  def set_cloned_voice
    @cloned_voice = current_user.cloned_voices.find(params[:id])
  end

  def cloned_voice_params
    params.require(:cloned_voice).permit(:name, :description, :labels, audio_samples: [])
  end

  def check_elevenlabs_configured
    unless Setting.elevenlabs_api_key.present?
      flash[:alert] = "ElevenLabs API ключ не настроен"
      redirect_to voice_generations_path
    end
  end
end
