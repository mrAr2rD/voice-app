require "open3"

module Transcriptions
  class AudioExtractor < ApplicationService
    SUPPORTED_VIDEO_FORMATS = %w[.mp4 .mov .avi .mkv .webm .flv .wmv].freeze

    def initialize(input_path, output_dir: nil)
      @input_path = input_path
      @output_dir = output_dir || Rails.root.join("tmp", "extracted")
    end

    def call
      ensure_output_dir
      validate_input

      output_path = generate_output_path
      result = extract_audio(output_path)

      if result[:success]
        duration = get_duration(output_path)
        success({ file_path: output_path, duration: duration })
      else
        failure(result[:error])
      end
    rescue StandardError => e
      failure("Ошибка извлечения аудио: #{e.message}")
    end

    private

    def ensure_output_dir
      FileUtils.mkdir_p(@output_dir)
    end

    def validate_input
      raise "Файл не существует" unless File.exist?(@input_path)
    end

    def generate_output_path
      basename = File.basename(@input_path, ".*")
      timestamp = Time.current.to_i
      File.join(@output_dir, "#{basename}_#{timestamp}.mp3")
    end

    def extract_audio(output_path)
      command = [
        "ffmpeg",
        "-i", @input_path,
        "-vn",
        "-acodec", "libmp3lame",
        "-ab", "192k",
        "-ar", "44100",
        "-y",
        output_path
      ]

      stdout, stderr, status = Open3.capture3(*command)

      if status.success? && File.exist?(output_path)
        { success: true }
      else
        { success: false, error: "FFmpeg error: #{stderr}" }
      end
    end

    def get_duration(file_path)
      command = [
        "ffprobe",
        "-v", "quiet",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        file_path
      ]
      stdout, _stderr, status = Open3.capture3(*command)
      stdout.strip.to_f if status.success?
    end
  end
end
