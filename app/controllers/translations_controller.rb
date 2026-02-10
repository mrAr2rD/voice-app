class TranslationsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :check_feature_enabled
  before_action :set_translation, only: [:show, :destroy, :download]

  def index
    @translations = current_user.translations.recent.limit(50)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { status: @translation.status, progress: @translation.in_progress? ? 50 : 100 } }
    end
  end

  def new
    @translation = Translation.new
    @transcriptions = current_user.transcriptions.completed.recent.limit(20)

    # Если передан transcription_id, заполняем текст
    if params[:transcription_id].present?
      transcription = current_user.transcriptions.completed.find_by(id: params[:transcription_id])
      if transcription
        @translation.source_text = transcription.full_text
      end
    end
  end

  def create
    @translation = current_user.translations.build(translation_params)

    if @translation.save
      TranslationJob.perform_later(@translation.id)
      redirect_to @translation, notice: "Перевод запущен"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @translation.destroy
    redirect_to translations_path, notice: "Перевод удалён"
  end

  def download
    format = params[:format] || "txt"
    filename = "translation_#{@translation.id}.#{format}"

    content = case format
    when "md"
      generate_markdown
    else
      @translation.translated_text || ""
    end

    send_data content, filename: filename, type: "text/plain; charset=utf-8"
  end

  private

  def set_translation
    @translation = current_user.translations.find(params[:id])
  end

  def translation_params
    params.require(:translation).permit(:source_text, :source_language, :target_language, :model)
  end

  def check_feature_enabled
    unless Setting.get(:translation_enabled)
      redirect_to root_path, alert: "Функция перевода временно отключена"
    end
  end

  def generate_markdown
    <<~MD
      # Перевод

      **Исходный язык:** #{@translation.source_language_name}
      **Целевой язык:** #{@translation.target_language_name}
      **Модель:** #{@translation.ai_model_name}
      **Дата:** #{@translation.created_at.strftime("%d.%m.%Y %H:%M")}

      ---

      ## Оригинал

      #{@translation.source_text}

      ---

      ## Перевод

      #{@translation.translated_text}
    MD
  end
end
