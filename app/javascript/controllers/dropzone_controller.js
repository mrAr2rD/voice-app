import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zone", "input", "filename"]

  dragover(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("border-indigo-400", "bg-indigo-50")
  }

  dragenter(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("border-indigo-400", "bg-indigo-50")
  }

  dragleave(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("border-indigo-400", "bg-indigo-50")
  }

  drop(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("border-indigo-400", "bg-indigo-50")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.showFilename(files[0].name)
    }
  }

  change(event) {
    const files = event.target.files
    if (files.length > 0) {
      this.showFilename(files[0].name)
    }
  }

  // Allow re-selecting the same file by clearing input value on click
  click(event) {
    // Skip if clicking on the input or label directly (they handle it themselves)
    if (event.target === this.inputTarget || event.target.tagName === 'LABEL') {
      this.inputTarget.value = ""
      return
    }

    // For clicks on other areas of the zone, trigger file dialog
    this.inputTarget.value = ""
    this.inputTarget.click()
  }

  showFilename(name) {
    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = name
      this.filenameTarget.classList.remove("hidden")
    }
  }
}
