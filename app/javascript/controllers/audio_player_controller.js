import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "progress", "time"]

  connect() {
    if (this.hasAudioTarget) {
      this.audioTarget.addEventListener("timeupdate", this.updateProgress.bind(this))
      this.audioTarget.addEventListener("loadedmetadata", this.updateDuration.bind(this))
    }
  }

  disconnect() {
    if (this.hasAudioTarget) {
      this.audioTarget.removeEventListener("timeupdate", this.updateProgress.bind(this))
      this.audioTarget.removeEventListener("loadedmetadata", this.updateDuration.bind(this))
    }
  }

  togglePlay() {
    if (this.audioTarget.paused) {
      this.audioTarget.play()
    } else {
      this.audioTarget.pause()
    }
  }

  updateProgress() {
    if (this.hasProgressTarget && this.audioTarget.duration) {
      const percent = (this.audioTarget.currentTime / this.audioTarget.duration) * 100
      this.progressTarget.style.width = `${percent}%`
    }
  }

  updateDuration() {
    if (this.hasTimeTarget) {
      this.timeTarget.textContent = this.formatTime(this.audioTarget.duration)
    }
  }

  seek(event) {
    const rect = event.currentTarget.getBoundingClientRect()
    const percent = (event.clientX - rect.left) / rect.width
    this.audioTarget.currentTime = percent * this.audioTarget.duration
  }

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }
}
