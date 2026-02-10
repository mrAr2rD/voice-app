class TranslationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(translation_id)
    translation = Translation.find(translation_id)
    return if translation.completed? || translation.failed?

    Translations::TranslateService.call(translation)
  end
end
