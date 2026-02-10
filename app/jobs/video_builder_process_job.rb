class VideoBuilderProcessJob < ApplicationJob
  queue_as :video_processing

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(video_builder_id)
    video_builder = VideoBuilder.find(video_builder_id)
    return if video_builder.completed? || video_builder.failed?

    VideoBuilding::ProcessService.call(video_builder)
  end
end
