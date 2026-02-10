import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "allBtn", "transcriptionBtn", "voiceBtn", "translationBtn", "videoBuilderBtn"]

  connect() {
    this.activeFilter = "all"
  }

  showAll() {
    this.activeFilter = "all"
    this.updateButtons()
    this.filterItems()
  }

  showTranscriptions() {
    this.activeFilter = "transcriptions"
    this.updateButtons()
    this.filterItems()
  }

  showVoice() {
    this.activeFilter = "voice"
    this.updateButtons()
    this.filterItems()
  }

  showTranslations() {
    this.activeFilter = "translations"
    this.updateButtons()
    this.filterItems()
  }

  showVideoBuilders() {
    this.activeFilter = "video-builders"
    this.updateButtons()
    this.filterItems()
  }

  updateButtons() {
    const activeStyle = "background: var(--color-graphite); color: var(--color-snow); border: none;"
    const inactiveStyle = "border: 1px solid var(--color-graphite); color: var(--color-cloud); background: transparent;"

    if (this.hasAllBtnTarget) {
      this.allBtnTarget.style.cssText = this.activeFilter === "all" ? activeStyle : inactiveStyle
    }
    if (this.hasTranscriptionBtnTarget) {
      this.transcriptionBtnTarget.style.cssText = this.activeFilter === "transcriptions" ? activeStyle : inactiveStyle
    }
    if (this.hasVoiceBtnTarget) {
      this.voiceBtnTarget.style.cssText = this.activeFilter === "voice" ? activeStyle : inactiveStyle
    }
    if (this.hasTranslationBtnTarget) {
      this.translationBtnTarget.style.cssText = this.activeFilter === "translations" ? activeStyle : inactiveStyle
    }
    if (this.hasVideoBuilderBtnTarget) {
      this.videoBuilderBtnTarget.style.cssText = this.activeFilter === "video-builders" ? activeStyle : inactiveStyle
    }
  }

  filterItems() {
    const items = this.listTarget.querySelectorAll(".activity-item")

    items.forEach(item => {
      if (this.activeFilter === "all") {
        item.style.display = ""
      } else if (this.activeFilter === "transcriptions") {
        item.style.display = item.classList.contains("activity-transcription") ? "" : "none"
      } else if (this.activeFilter === "voice") {
        item.style.display = item.classList.contains("activity-voice") ? "" : "none"
      } else if (this.activeFilter === "translations") {
        item.style.display = item.classList.contains("activity-translation") ? "" : "none"
      } else if (this.activeFilter === "video-builders") {
        item.style.display = item.classList.contains("activity-video-builder") ? "" : "none"
      }
    })
  }
}
