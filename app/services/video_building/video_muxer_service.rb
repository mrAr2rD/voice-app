module VideoBuilding
  class VideoMuxerService < ApplicationService
    def initialize(video_path, audio_path, output_path)
      @video_path = video_path
      @audio_path = audio_path
      @output_path = output_path
    end

    def call
      return failure("Видео файл не найден") unless File.exist?(@video_path)
      return failure("Аудио файл не найден") unless File.exist?(@audio_path)

      mux_video_audio
    rescue StandardError => e
      failure("Ошибка объединения видео и аудио: #{e.message}")
    end

    private

    def mux_video_audio
      cmd = [
        "ffmpeg",
        "-y",
        "-i", @video_path,
        "-i", @audio_path,
        "-c:v", "copy",
        "-c:a", "aac",
        "-b:a", "192k",
        "-map", "0:v:0",
        "-map", "1:a:0",
        "-shortest",
        @output_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        Rails.logger.error "FFmpeg mux error: #{stderr}"
        return failure("FFmpeg не удалось объединить видео и аудио")
      end

      success(@output_path)
    end
  end
end
