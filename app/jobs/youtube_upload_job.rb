class YoutubeUploadJob < ApplicationJob
  queue_as :youtube

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(video_builder_id)
    video_builder = VideoBuilder.find(video_builder_id)
    return unless video_builder.can_publish?

    Youtube::UploadService.call(video_builder)
  end
end
