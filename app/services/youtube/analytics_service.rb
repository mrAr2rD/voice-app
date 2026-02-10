module Youtube
  class AnalyticsService < ApplicationService
    ANALYTICS_API_URL = "https://youtubeanalytics.googleapis.com/v2".freeze
    DATA_API_URL = "https://www.googleapis.com/youtube/v3".freeze

    def initialize(user, video_id: nil, days: 28)
      @user = user
      @video_id = video_id
      @days = days
      @credential = user.youtube_credential
    end

    def call
      return failure("YouTube не подключён") unless @credential&.access_token

      refresh_token_if_needed

      if @video_id
        fetch_video_analytics
      else
        fetch_channel_analytics
      end
    end

    private

    def refresh_token_if_needed
      return unless @credential.expires_at && @credential.expires_at < Time.current

      TokenRefreshService.call(@credential)
    end

    def fetch_channel_analytics
      end_date = Date.today
      start_date = end_date - @days.days

      response = connection(ANALYTICS_API_URL).get("/v2/reports") do |req|
        req.headers["Authorization"] = "Bearer #{@credential.access_token}"
        req.params = {
          ids: "channel==MINE",
          startDate: start_date.to_s,
          endDate: end_date.to_s,
          metrics: "views,estimatedMinutesWatched,averageViewDuration,subscribersGained,subscribersLost,likes,dislikes,comments,shares",
          dimensions: "day",
          sort: "day"
        }
      end

      parse_analytics_response(response, :channel)
    end

    def fetch_video_analytics
      end_date = Date.today
      start_date = end_date - @days.days

      video_response = connection(DATA_API_URL).get("/videos") do |req|
        req.headers["Authorization"] = "Bearer #{@credential.access_token}"
        req.params = {
          part: "snippet,statistics,contentDetails",
          id: @video_id
        }
      end

      analytics_response = connection(ANALYTICS_API_URL).get("/v2/reports") do |req|
        req.headers["Authorization"] = "Bearer #{@credential.access_token}"
        req.params = {
          ids: "channel==MINE",
          filters: "video==#{@video_id}",
          startDate: start_date.to_s,
          endDate: end_date.to_s,
          metrics: "views,estimatedMinutesWatched,averageViewDuration,likes,dislikes,comments,shares,averageViewPercentage",
          dimensions: "day",
          sort: "day"
        }
      end

      parse_video_analytics(video_response, analytics_response)
    end

    def parse_analytics_response(response, type)
      return failure("API error: #{response.status}") unless response.success?

      data = JSON.parse(response.body)

      columns = data["columnHeaders"]&.map { |h| h["name"] } || []
      rows = data["rows"] || []

      analytics = {
        type: type,
        period: "#{@days} дней",
        daily_data: parse_daily_data(columns, rows),
        totals: calculate_totals(columns, rows)
      }

      success(analytics)
    rescue JSON::ParserError => e
      failure("Invalid response: #{e.message}")
    rescue StandardError => e
      failure(e.message)
    end

    def parse_video_analytics(video_response, analytics_response)
      unless video_response.success? && analytics_response.success?
        return failure("API error")
      end

      video_data = JSON.parse(video_response.body)
      analytics_data = JSON.parse(analytics_response.body)

      video = video_data.dig("items", 0)
      return failure("Video not found") unless video

      columns = analytics_data["columnHeaders"]&.map { |h| h["name"] } || []
      rows = analytics_data["rows"] || []

      analytics = {
        type: :video,
        video: {
          id: video["id"],
          title: video.dig("snippet", "title"),
          thumbnail: video.dig("snippet", "thumbnails", "medium", "url"),
          published_at: video.dig("snippet", "publishedAt"),
          duration: video.dig("contentDetails", "duration"),
          views: video.dig("statistics", "viewCount").to_i,
          likes: video.dig("statistics", "likeCount").to_i,
          comments: video.dig("statistics", "commentCount").to_i
        },
        period: "#{@days} дней",
        daily_data: parse_daily_data(columns, rows),
        totals: calculate_totals(columns, rows)
      }

      success(analytics)
    rescue JSON::ParserError => e
      failure("Invalid response: #{e.message}")
    rescue StandardError => e
      failure(e.message)
    end

    def parse_daily_data(columns, rows)
      rows.map do |row|
        data = {}
        columns.each_with_index do |col, i|
          data[col.underscore.to_sym] = row[i]
        end
        data
      end
    end

    def calculate_totals(columns, rows)
      return {} if rows.empty?

      totals = {}
      columns.each_with_index do |col, i|
        next if col == "day"
        values = rows.map { |r| r[i].to_f }
        totals[col.underscore.to_sym] = values.sum.round(2)
      end
      totals
    end

    def connection(base_url)
      Faraday.new(url: base_url) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 30
        f.options.open_timeout = 10
      end
    end
  end
end
