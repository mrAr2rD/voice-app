import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 3000 },
    url: String
  }

  static targets = ["progressBar", "progressText"]

  connect() {
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    if (this.urlValue) {
      this.poll()
    }
  }

  stopPolling() {
    if (this.pollTimeout) {
      clearTimeout(this.pollTimeout)
    }
  }

  poll() {
    fetch(this.urlValue + ".json", {
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => {
      if (response.ok) {
        return response.json()
      }
      throw new Error("Network response was not ok")
    })
    .then(data => {
      if (data.status === "completed" || data.status === "failed") {
        window.location.reload()
      } else {
        this.updateProgress(data.progress || 0)
        this.pollTimeout = setTimeout(() => this.poll(), this.intervalValue)
      }
    })
    .catch(() => {
      this.pollTimeout = setTimeout(() => this.poll(), this.intervalValue)
    })
  }

  updateProgress(progress) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${progress}%`
    }
  }
}
