class ScriptsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :check_openrouter_configured, only: %i[new create]
  before_action :set_script, only: %i[show destroy copy_to_tts]

  def index
    @scripts = current_user.scripts.includes(:project).recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @script.status } }
    end
  end

  def new
    @script = current_user.scripts.build
    @projects = current_user.projects.order(:name)
  end

  def create
    @script = current_user.scripts.build(script_params)

    if @script.save
      ScriptGenerationJob.perform_later(@script.id)
      flash[:notice] = "Генерация сценария запущена"
      redirect_to @script
    else
      @projects = current_user.projects.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @script.destroy
    flash[:notice] = "Сценарий удалён"
    redirect_to scripts_path
  end

  def copy_to_tts
    unless @script.completed? && @script.content.present?
      flash[:alert] = "Сценарий ещё не готов"
      return redirect_to @script
    end

    voice_gen = current_user.voice_generations.create!(
      text: @script.content.gsub(/\[(INTRO|MAIN|CTA|OUTRO)\]/, "").strip,
      provider: :elevenlabs,
      voice_id: Tts::ElevenlabsClient::DEFAULT_VOICES.first[:id],
      voice_name: Tts::ElevenlabsClient::DEFAULT_VOICES.first[:name],
      project: @script.project
    )

    flash[:notice] = "Сценарий отправлен на озвучку"
    redirect_to new_voice_generation_path(text: voice_gen.text.truncate(200))
  end

  private

  def set_script
    @script = current_user.scripts.find(params[:id])
  end

  def script_params
    params.require(:script).permit(:title, :script_type, :topic, :model, :language, :duration_seconds, :project_id)
  end

  def check_openrouter_configured
    unless Setting.openrouter_api_key.present?
      flash[:alert] = "OpenRouter API ключ не настроен"
      redirect_to scripts_path
    end
  end
end
