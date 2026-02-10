module VideoBuilding
  class AudioMergerService < ApplicationService
    def initialize(audio_files, output_path)
      @audio_files = audio_files
      @output_path = output_path
    end

    def call
      return failure("Нет аудио файлов для склейки") if @audio_files.empty?

      if @audio_files.size == 1
        FileUtils.cp(@audio_files.first, @output_path)
        return success(@output_path)
      end

      merge_audio_files
    rescue StandardError => e
      failure("Ошибка склейки аудио: #{e.message}")
    end

    private

    def merge_audio_files
      list_file = Tempfile.new(["audio_list", ".txt"])

      begin
        @audio_files.each do |file|
          list_file.puts "file '#{file}'"
        end
        list_file.close

        cmd = [
          "ffmpeg",
          "-y",
          "-f", "concat",
          "-safe", "0",
          "-i", list_file.path,
          "-c", "copy",
          @output_path
        ]

        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          Rails.logger.error "FFmpeg audio merge error: #{stderr}"
          return failure("FFmpeg не удалось склеить аудио файлы")
        end

        success(@output_path)
      ensure
        list_file.unlink
      end
    end
  end
end
