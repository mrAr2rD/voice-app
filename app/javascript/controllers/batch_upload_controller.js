import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "fileList", "fileCount", "textArea"]

  connect() {
    this.files = []
  }

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.style.borderColor = "var(--color-neon-purple)"
  }

  dragenter(event) {
    event.preventDefault()
    this.dropzoneTarget.style.borderColor = "var(--color-neon-purple)"
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.style.borderColor = "var(--color-graphite)"
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.style.borderColor = "var(--color-graphite)"

    const files = event.dataTransfer.files
    this.addFiles(files)
  }

  click(event) {
    if (event.target === this.inputTarget) return
    this.inputTarget.click()
  }

  handleFiles(event) {
    this.addFiles(event.target.files)
  }

  addFiles(fileList) {
    const validTypes = [
      'audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/x-wav', 'audio/flac',
      'video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo'
    ]

    const newFiles = Array.from(fileList).filter(file => {
      const isValid = validTypes.some(type => file.type.startsWith(type.split('/')[0]))
      const isSmallEnough = file.size <= 500 * 1024 * 1024
      return isValid && isSmallEnough
    })

    if (this.files.length + newFiles.length > 20) {
      alert("Максимум 20 файлов")
      return
    }

    this.files = [...this.files, ...newFiles]
    this.updateFileList()
    this.updateInput()
    this.updateFileCount()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.updateFileList()
    this.updateInput()
    this.updateFileCount()
  }

  updateFileList() {
    if (!this.hasFileListTarget) return

    this.fileListTarget.innerHTML = this.files.map((file, index) => `
      <div class="flex items-center justify-between p-3 rounded-lg" style="background: var(--color-obsidian);">
        <div class="flex items-center flex-1 min-w-0">
          <svg class="w-5 h-5 mr-3 flex-shrink-0" style="color: var(--color-neon-purple);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            ${file.type.startsWith('video/') ?
              '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>' :
              '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"/>'
            }
          </svg>
          <span class="truncate" style="color: var(--color-cloud);">${file.name}</span>
          <span class="ml-2 text-xs flex-shrink-0" style="color: var(--color-mist);">${this.formatSize(file.size)}</span>
        </div>
        <button type="button" data-action="click->batch-upload#removeFile" data-index="${index}"
                class="p-1 rounded transition-colors ml-2 flex-shrink-0" style="color: var(--color-coral);">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `).join('')
  }

  updateInput() {
    const dt = new DataTransfer()
    this.files.forEach(file => dt.items.add(file))
    this.inputTarget.files = dt.files
  }

  updateFileCount() {
    if (this.hasFileCountTarget) {
      this.fileCountTarget.textContent = this.files.length
    }
  }

  formatSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / (1024 * 1024)).toFixed(1) + " MB"
  }
}
