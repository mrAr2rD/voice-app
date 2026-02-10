import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtitlesOptions"]

  connect() {
    this.updateSubtitlesVisibility()
  }

  toggleSubtitles(event) {
    this.updateSubtitlesVisibility()
  }

  updateSubtitlesVisibility() {
    const checkbox = this.element.querySelector('[name="video_builder[subtitles_enabled]"]')
    if (this.hasSubtitlesOptionsTarget) {
      if (checkbox && checkbox.checked) {
        this.subtitlesOptionsTarget.classList.remove("hidden")
      } else {
        this.subtitlesOptionsTarget.classList.add("hidden")
      }
    }
  }
}
