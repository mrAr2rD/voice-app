module Clipping
  class ClipCreatorService < ApplicationService
    def initialize(video_clip)
      @video_clip = video_clip
    end

    def call
      return failure("Исходное видео не найдено") unless source_video_path

      @video_clip.update!(status: :processing)

      Dir.mktmpdir do |tmpdir|
        output_path = File.join(tmpdir, "clip_#{@video_clip.id}.mp4")

        result = create_clip(output_path)

        if result[:success]
          attach_output(output_path)
          @video_clip.update!(status: :completed)
          success(@video_clip)
        else
          @video_clip.update!(status: :failed, error_message: result[:error])
          failure(result[:error])
        end
      end
    rescue StandardError => e
      @video_clip.update!(status: :failed, error_message: e.message)
      failure(e.message)
    end

    private

    def source_video_path
      if @video_clip.source_video.attached?
        download_to_tempfile(@video_clip.source_video)
      elsif @video_clip.source_video_builder&.output_video&.attached?
        download_to_tempfile(@video_clip.source_video_builder.output_video)
      end
    end

    def download_to_tempfile(attachment)
      tempfile = Tempfile.new([ "source", File.extname(attachment.filename.to_s) ])
      tempfile.binmode
      tempfile.write(attachment.download)
      tempfile.rewind
      tempfile.path
    end

    def create_clip(output_path)
      input_path = source_video_path
      return { success: false, error: "No source video" } unless input_path

      filter_complex = build_filter_complex
      duration = @video_clip.end_time - @video_clip.start_time

      cmd = [
        "ffmpeg", "-y",
        "-ss", @video_clip.start_time.to_s,
        "-i", input_path,
        "-t", duration.to_s,
        "-filter_complex", filter_complex,
        "-map", "[v]",
        "-map", "0:a?",
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "23",
        "-c:a", "aac",
        "-b:a", "128k",
        "-movflags", "+faststart",
        output_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      if status.success? && File.exist?(output_path)
        { success: true }
      else
        { success: false, error: stderr.truncate(500) }
      end
    end

    def build_filter_complex
      case @video_clip.aspect_ratio
      when "9:16"
        build_vertical_filter(9, 16)
      when "1:1"
        build_square_filter
      when "4:5"
        build_vertical_filter(4, 5)
      else
        "[0:v]copy[v]"
      end
    end

    def build_vertical_filter(width_ratio, height_ratio)
      <<~FILTER.gsub("\n", "").strip
        [0:v]split=2[bg][fg];
        [bg]scale=1080:1920:force_original_aspect_ratio=increase,
        crop=1080:1920,boxblur=20:5[bg_blur];
        [fg]scale=1080:1080:force_original_aspect_ratio=decrease,
        pad=1080:1080:(ow-iw)/2:(oh-ih)/2:color=black@0[fg_scaled];
        [bg_blur][fg_scaled]overlay=(W-w)/2:(H-h)/2[v]
      FILTER
    end

    def build_square_filter
      <<~FILTER.gsub("\n", "").strip
        [0:v]scale=1080:1080:force_original_aspect_ratio=decrease,
        pad=1080:1080:(ow-iw)/2:(oh-ih)/2:color=black[v]
      FILTER
    end

    def attach_output(output_path)
      @video_clip.output_video.attach(
        io: File.open(output_path),
        filename: "clip_#{@video_clip.id}.mp4",
        content_type: "video/mp4"
      )
    end
  end
end
