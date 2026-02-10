module VideoBuilding
  class SubtitleBurnerService < ApplicationService
    STYLES = {
      "default" => {
        fontsize: 24,
        fontcolor: "white",
        borderw: 0
      },
      "outlined" => {
        fontsize: 24,
        fontcolor: "white",
        borderw: 2,
        bordercolor: "black"
      },
      "shadow" => {
        fontsize: 24,
        fontcolor: "white",
        shadowx: 2,
        shadowy: 2,
        shadowcolor: "black"
      },
      "boxed" => {
        fontsize: 24,
        fontcolor: "white",
        box: 1,
        boxcolor: "black@0.7",
        boxborderw: 5
      }
    }.freeze

    POSITIONS = {
      "top" => "y=50",
      "center" => "y=(h-text_h)/2",
      "bottom" => "y=h-th-50"
    }.freeze

    def initialize(video_path, subtitles_path, output_path, options = {})
      @video_path = video_path
      @subtitles_path = subtitles_path
      @output_path = output_path
      @style = options[:style] || "default"
      @position = options[:position] || "bottom"
      @font_size = options[:font_size] || 24
    end

    def call
      return failure("Видео файл не найден") unless File.exist?(@video_path)
      return failure("Файл субтитров не найден") unless File.exist?(@subtitles_path)

      burn_subtitles
    rescue StandardError => e
      failure("Ошибка добавления субтитров: #{e.message}")
    end

    private

    def burn_subtitles
      filter = build_subtitle_filter

      cmd = [
        "ffmpeg",
        "-y",
        "-i", @video_path,
        "-vf", filter,
        "-c:a", "copy",
        @output_path
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        Rails.logger.error "FFmpeg subtitle error: #{stderr}"
        return failure("FFmpeg не удалось добавить субтитры")
      end

      success(@output_path)
    end

    def build_subtitle_filter
      escaped_path = escape_ffmpeg_path(@subtitles_path)
      style_options = build_style_options

      "subtitles='#{escaped_path}':force_style='#{style_options}'"
    end

    def escape_ffmpeg_path(path)
      # FFmpeg filter escaping requires: \ : ' ; [ ] ,
      path
        .gsub("\\", "\\\\\\\\")  # backslash first
        .gsub(":", "\\:")
        .gsub("'", "\\'")
        .gsub(";", "\\;")
        .gsub("[", "\\[")
        .gsub("]", "\\]")
        .gsub(",", "\\,")
    end

    def build_style_options
      style_config = STYLES[@style] || STYLES["default"]
      position_y = POSITIONS[@position] || POSITIONS["bottom"]

      options = [
        "FontSize=#{@font_size}",
        "PrimaryColour=&H00FFFFFF",
        "Alignment=2"
      ]

      if style_config[:borderw]&.positive?
        options << "BorderStyle=1"
        options << "Outline=#{style_config[:borderw]}"
        options << "OutlineColour=&H00000000"
      end

      if style_config[:box]
        options << "BorderStyle=4"
        options << "BackColour=&H80000000"
      end

      if style_config[:shadowx]
        options << "Shadow=#{style_config[:shadowx]}"
      end

      case @position
      when "top"
        options << "MarginV=50"
        options << "Alignment=8"
      when "center"
        options << "Alignment=5"
      when "bottom"
        options << "MarginV=50"
        options << "Alignment=2"
      end

      options.join(",")
    end
  end
end
