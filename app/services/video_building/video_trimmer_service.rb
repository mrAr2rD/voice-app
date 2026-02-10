module VideoBuilding
  class VideoTrimmerService < ApplicationService
    def initialize(video_path, duration, output_path)
      @video_path = video_path
      @duration = duration
      @output_path = output_path
    end

    def call
      return failure("Видео файл не найден") unless File.exist?(@video_path)
      return failure("Длительность должна быть положительной") unless @duration.to_f > 0

      trim_video
    rescue StandardError => e
      failure("Ошибка обрезки видео: #{e.message}")
    end

    private

    def trim_video
      cmd = [
        "ffmpeg",
        "-y",
        "-i", @video_path,
        "-t", @duration.to_s,
        "-c", "copy",
        "-avoid_negative_ts", "make_zero",
        @output_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        Rails.logger.error "FFmpeg trim error: #{stderr}"
        return failure("FFmpeg не удалось обрезать видео")
      end

      success(@output_path)
    end
  end
end
