module VideoBuilding
  class ProcessService < ApplicationService
    def initialize(video_builder)
      @video_builder = video_builder
      @temp_files = []
    end

    def call
      return failure("Видео-билдер не найден") unless @video_builder

      # Race condition protection: only process if currently draft
      updated = VideoBuilder.where(id: @video_builder.id, status: :draft)
                            .update_all(status: :processing, progress: 0)
      return failure("Видео-билдер уже обрабатывается") if updated.zero?

      @video_builder.reload
      process_video
    rescue StandardError => e
      Rails.logger.error "VideoBuilder::ProcessService error: #{e.message}\n#{e.backtrace.join("\n")}"
      @video_builder.update!(status: :failed, error_message: e.message)
      failure(e.message)
    ensure
      cleanup_temp_files
    end

    private

    def process_video
      update_progress(10, "Подготовка аудио...")
      audio_path = prepare_audio
      return failure(@video_builder.error_message) unless audio_path

      update_progress(20, "Анализ длительности...")
      audio_duration = get_duration(audio_path)
      return failure("Не удалось определить длительность аудио") unless audio_duration

      update_progress(30, "Подготовка видео...")
      video_path = download_source_video
      return failure("Не удалось получить исходное видео") unless video_path

      update_progress(40, "Обработка видео...")
      processed_video = process_video_file(video_path, audio_duration)
      return failure(@video_builder.error_message) unless processed_video

      update_progress(60, "Объединение видео и аудио...")
      muxed_path = mux_video_audio(processed_video, audio_path)
      return failure(@video_builder.error_message) unless muxed_path

      final_path = muxed_path

      if @video_builder.subtitles_enabled && @video_builder.subtitles_file.attached?
        update_progress(80, "Добавление субтитров...")
        subtitles_result = add_subtitles(muxed_path)
        final_path = subtitles_result if subtitles_result
      end

      update_progress(90, "Сохранение результата...")
      save_output(final_path, audio_duration)

      update_progress(100, "Завершено")
      @video_builder.update!(status: :completed, progress: 100)

      success(@video_builder)
    end

    def prepare_audio
      audio_sources = @video_builder.audio_sources.ordered.includes(:voice_generation)

      if audio_sources.any?
        audio_files = audio_sources.filter_map do |source|
          next unless source.voice_generation&.audio_file&.attached?
          download_attachment(source.voice_generation.audio_file)
        end

        return nil if audio_files.empty?

        if audio_files.size == 1
          audio_files.first
        else
          merged_path = temp_file_path("merged_audio", ".mp3")
          result = AudioMergerService.call(audio_files, merged_path)
          return nil unless result.success?
          merged_path
        end
      elsif @video_builder.source_audio.attached?
        download_attachment(@video_builder.source_audio)
      else
        @video_builder.update!(status: :failed, error_message: "Нет аудио источников")
        nil
      end
    end

    def download_source_video
      if @video_builder.source_video.attached?
        download_attachment(@video_builder.source_video)
      elsif @video_builder.background_videos.attached?
        download_attachment(@video_builder.background_videos.first)
      end
    end

    def process_video_file(video_path, target_duration)
      output_path = temp_file_path("processed_video", ".mp4")

      result = if @video_builder.video_mode == "loop"
        VideoLooperService.call(video_path, target_duration, output_path)
      else
        VideoTrimmerService.call(video_path, target_duration, output_path)
      end

      if result.failure?
        @video_builder.update!(error_message: result.error)
        return nil
      end

      output_path
    end

    def mux_video_audio(video_path, audio_path)
      output_path = temp_file_path("muxed", ".mp4")
      result = VideoMuxerService.call(video_path, audio_path, output_path)

      if result.failure?
        @video_builder.update!(error_message: result.error)
        return nil
      end

      output_path
    end

    def add_subtitles(video_path)
      subtitles_path = download_attachment(@video_builder.subtitles_file)
      return nil unless subtitles_path

      output_path = temp_file_path("subtitled", ".mp4")
      result = SubtitleBurnerService.call(
        video_path,
        subtitles_path,
        output_path,
        style: @video_builder.subtitles_style,
        position: @video_builder.subtitles_position,
        font_size: @video_builder.subtitles_font_size
      )

      result.success? ? output_path : nil
    end

    def save_output(video_path, duration)
      @video_builder.output_video.attach(
        io: File.open(video_path),
        filename: "output_#{@video_builder.id}.mp4",
        content_type: "video/mp4"
      )
      @video_builder.update!(output_duration: duration)
    end

    def get_duration(file_path)
      result = DurationAnalyzer.call(file_path)
      result.success? ? result.data : nil
    end

    def download_attachment(attachment)
      return nil unless attachment.attached?

      ext = File.extname(attachment.filename.to_s)
      path = temp_file_path("download", ext)

      File.open(path, "wb") do |file|
        attachment.download { |chunk| file.write(chunk) }
      end

      path
    end

    def temp_file_path(prefix, extension)
      path = Rails.root.join("tmp", "video_builder", "#{prefix}_#{SecureRandom.hex(8)}#{extension}")
      FileUtils.mkdir_p(File.dirname(path))
      @temp_files << path.to_s
      path.to_s
    end

    def cleanup_temp_files
      @temp_files.each do |path|
        FileUtils.rm_f(path) if File.exist?(path)
      end
    end

    def update_progress(progress, message = nil)
      @video_builder.update!(progress: progress)
      Rails.logger.info "[VideoBuilder ##{@video_builder.id}] #{progress}% - #{message}" if message
    end
  end
end
