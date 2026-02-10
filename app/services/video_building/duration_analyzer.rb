module VideoBuilding
  class DurationAnalyzer < ApplicationService
    def initialize(file_path)
      @file_path = file_path
    end

    def call
      return failure("Файл не найден: #{@file_path}") unless File.exist?(@file_path)

      duration = get_duration
      return failure("Не удалось определить длительность файла") unless duration

      success(duration)
    rescue StandardError => e
      failure("Ошибка анализа длительности: #{e.message}")
    end

    private

    def get_duration
      cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "csv=p=0",
        @file_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        Rails.logger.error "FFprobe error: #{stderr}"
        return nil
      end

      duration = stdout.strip.to_f
      duration > 0 ? duration : nil
    end
  end
end
