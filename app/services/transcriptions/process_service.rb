module Transcriptions
  class ProcessService < ApplicationService
    def initialize(transcription)
      @transcription = transcription
    end

    def call
      @transcription.update!(status: :processing, progress: 10)

      audio_path = prepare_audio_file
      return failure(@error) if @error

      @transcription.update!(status: :transcribing, progress: 50)

      result = transcribe_audio(audio_path)
      return failure(result[:error]) if result[:error]

      @transcription.update!(progress: 80)

      parse_result = ResultParser.call(@transcription, result[:data])
      return failure(parse_result.error) if parse_result.failure?

      @transcription.update!(status: :completed, progress: 100)
      success(@transcription)
    rescue StandardError => e
      handle_error(e)
      failure(e.message)
    ensure
      cleanup_temp_files
    end

    private

    def prepare_audio_file
      case @transcription.source_type
      when "youtube_url"
        download_from_youtube
      when "video_upload"
        extract_audio_from_video
      when "audio_upload"
        download_source_file
      end
    end

    def download_from_youtube
      @transcription.update!(status: :extracting_audio, progress: 20)

      result = YoutubeDownloader.call(@transcription.youtube_url)
      if result.success?
        @transcription.update!(
          original_filename: result.data[:title],
          duration: result.data[:duration]
        )
        @temp_files = [result.data[:file_path]]
        result.data[:file_path]
      else
        @error = result.error
        nil
      end
    end

    def extract_audio_from_video
      @transcription.update!(status: :extracting_audio, progress: 20)

      source_path = download_source_file
      return nil unless source_path

      result = AudioExtractor.call(source_path)
      if result.success?
        attach_extracted_audio(result.data[:file_path])
        @transcription.update!(duration: result.data[:duration])
        @temp_files ||= []
        @temp_files << result.data[:file_path]
        result.data[:file_path]
      else
        @error = result.error
        nil
      end
    end

    def download_source_file
      return nil unless @transcription.source_file.attached?

      temp_path = Rails.root.join("tmp", "uploads", "#{SecureRandom.uuid}_#{@transcription.source_file.filename}")
      FileUtils.mkdir_p(File.dirname(temp_path))

      File.open(temp_path, "wb") do |f|
        @transcription.source_file.download { |chunk| f.write(chunk) }
      end

      @temp_files ||= []
      @temp_files << temp_path.to_s
      temp_path.to_s
    end

    def attach_extracted_audio(file_path)
      @transcription.extracted_audio.attach(
        io: File.open(file_path),
        filename: "extracted_audio.mp3",
        content_type: "audio/mpeg"
      )
    end

    def transcribe_audio(audio_path)
      client = NexaraClient.new
      client.transcribe(audio_path, language: @transcription.language)
    end

    def handle_error(error)
      Rails.logger.error "Transcription error: #{error.message}\n#{error.backtrace.join("\n")}"
      @transcription.update!(
        status: :failed,
        error_message: error.message
      )
    end

    def cleanup_temp_files
      return unless @temp_files

      @temp_files.each do |path|
        FileUtils.rm_f(path) if path && File.exist?(path)
      end
    end
  end
end
