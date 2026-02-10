class VideoClipJob < ApplicationJob
  queue_as :video_processing

  def perform(video_clip_id)
    video_clip = VideoClip.find(video_clip_id)
    Clipping::ClipCreatorService.call(video_clip)
  end
end
