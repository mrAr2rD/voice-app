import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "providerInput",
    "elevenlabsCard",
    "openaiCard",
    "elevenlabsVoices",
    "openaiVoices",
    "elevenlabsSelect",
    "openaiSelect",
    "voiceNameInput",
    "charCount"
  ]

  connect() {
    this.updateCharCount()
    this.updateVoiceName()

    // Listen to select changes
    if (this.hasElevenlabsSelectTarget) {
      this.elevenlabsSelectTarget.addEventListener("change", () => this.updateVoiceName())
    }
    if (this.hasOpenaiSelectTarget) {
      this.openaiSelectTarget.addEventListener("change", () => this.updateVoiceName())
    }
  }

  selectProvider(event) {
    const provider = event.currentTarget.dataset.provider
    const radioButton = event.currentTarget.querySelector("input[type='radio']")

    if (radioButton) {
      radioButton.checked = true
    }

    this.updateCardStyles(provider)
    this.updateVoiceLists(provider)
    this.updateVoiceName()
  }

  updateCardStyles(provider) {
    if (this.hasElevenlabsCardTarget && this.hasOpenaiCardTarget) {
      if (provider === "elevenlabs") {
        this.elevenlabsCardTarget.style.borderColor = "var(--color-neon-purple)"
        this.openaiCardTarget.style.borderColor = "transparent"
      } else {
        this.openaiCardTarget.style.borderColor = "var(--color-neon-green)"
        this.elevenlabsCardTarget.style.borderColor = "transparent"
      }
    }
  }

  updateVoiceLists(provider) {
    if (this.hasElevenlabsVoicesTarget && this.hasOpenaiVoicesTarget) {
      if (provider === "elevenlabs") {
        this.elevenlabsVoicesTarget.classList.remove("hidden")
        this.openaiVoicesTarget.classList.add("hidden")
        if (this.hasOpenaiSelectTarget) {
          this.openaiSelectTarget.disabled = true
          this.openaiSelectTarget.removeAttribute("name")
        }
        if (this.hasElevenlabsSelectTarget) {
          this.elevenlabsSelectTarget.disabled = false
          this.elevenlabsSelectTarget.name = "voice_generation[voice_id]"
        }
      } else {
        this.openaiVoicesTarget.classList.remove("hidden")
        this.elevenlabsVoicesTarget.classList.add("hidden")
        if (this.hasElevenlabsSelectTarget) {
          this.elevenlabsSelectTarget.disabled = true
          this.elevenlabsSelectTarget.removeAttribute("name")
        }
        if (this.hasOpenaiSelectTarget) {
          this.openaiSelectTarget.disabled = false
          this.openaiSelectTarget.name = "voice_generation[voice_id]"
        }
      }
    }
  }

  updateVoiceName() {
    if (!this.hasVoiceNameInputTarget) return

    const activeSelect = this.getActiveSelect()
    if (activeSelect && activeSelect.selectedIndex > 0) {
      this.voiceNameInputTarget.value = activeSelect.options[activeSelect.selectedIndex].text
    } else {
      this.voiceNameInputTarget.value = ""
    }
  }

  getActiveSelect() {
    const elevenlabsRadio = this.element.querySelector("input[value='elevenlabs']")
    if (elevenlabsRadio && elevenlabsRadio.checked && this.hasElevenlabsSelectTarget) {
      return this.elevenlabsSelectTarget
    }
    if (this.hasOpenaiSelectTarget) {
      return this.openaiSelectTarget
    }
    return null
  }

  updateCharCount(event) {
    if (!this.hasCharCountTarget) return

    const textArea = this.element.querySelector("textarea")
    if (textArea) {
      this.charCountTarget.textContent = textArea.value.length
    }
  }
}
