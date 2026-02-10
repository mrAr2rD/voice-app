module VideoBuilding
  class VideoLooperService < ApplicationService
    def initialize(video_path, target_duration, output_path)
      @video_path = video_path
      @target_duration = target_duration
      @output_path = output_path
    end

    def call
      return failure("Видео файл не найден") unless File.exist?(@video_path)
      return failure("Целевая длительность должна быть положительной") unless @target_duration.to_f > 0

      loop_video
    rescue StandardError => e
      failure("Ошибка зацикливания видео: #{e.message}")
    end

    private

    def loop_video
      cmd = [
        "ffmpeg",
        "-y",
        "-stream_loop", "-1",
        "-i", @video_path,
        "-t", @target_duration.to_s,
        "-c", "copy",
        @output_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        Rails.logger.error "FFmpeg loop error: #{stderr}"
        return failure("FFmpeg не удалось зациклить видео")
      end

      success(@output_path)
    end
  end
end
