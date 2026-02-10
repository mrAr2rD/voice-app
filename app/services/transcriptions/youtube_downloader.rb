require "open3"

module Transcriptions
  class YoutubeDownloader < ApplicationService
    MAX_DURATION = 7200

    def initialize(url, output_dir: nil)
      @url = url
      @output_dir = output_dir || Rails.root.join("tmp", "downloads")
    end

    def call
      ensure_output_dir
      validate_url

      info = fetch_video_info
      return failure(info[:error]) if info[:error]
      return failure("Видео слишком длинное (максимум 2 часа)") if info[:duration].to_i > MAX_DURATION

      result = download_audio
      return failure(result[:error]) if result[:error]

      success({
        file_path: result[:file_path],
        title: info[:title],
        duration: info[:duration]
      })
    rescue StandardError => e
      failure("Ошибка загрузки: #{e.message}")
    end

    private

    def ensure_output_dir
      FileUtils.mkdir_p(@output_dir)
    end

    def validate_url
      unless @url.match?(%r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+})
        raise "Некорректный YouTube URL"
      end
    end

    def fetch_video_info
      command = [ "yt-dlp", "--dump-json", "--no-download", @url ]
      stdout, _stderr, status = Open3.capture3(*command)
      return { error: "Не удалось получить информацию о видео" } unless status.success?

      data = JSON.parse(stdout)
      { title: data["title"], duration: data["duration"] }
    rescue JSON::ParserError
      { error: "Ошибка парсинга информации о видео" }
    end

    def download_audio
      output_template = File.join(@output_dir, "%(id)s.%(ext)s")

      command = [
        "yt-dlp",
        "-x",
        "--audio-format", "mp3",
        "--audio-quality", "0",
        "-o", output_template,
        "--no-playlist",
        "--max-filesize", "500M",
        @url
      ]

      result = system(*command, [ :out, :err ] => "/dev/null")
      return { error: "Не удалось скачать аудио" } unless result

      video_id = extract_video_id
      file_path = File.join(@output_dir, "#{video_id}.mp3")

      if File.exist?(file_path)
        { file_path: file_path }
      else
        { error: "Файл не найден после загрузки" }
      end
    end

    def extract_video_id
      if @url.include?("youtu.be/")
        @url.split("youtu.be/").last.split(/[?&]/).first
      elsif @url.include?("watch?v=")
        @url.split("v=").last.split(/[?&]/).first
      else
        raise "Не удалось извлечь ID видео"
      end
    end
  end
end
