import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "fileList"]

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
    const newFiles = Array.from(fileList).filter(file => {
      return file.type.startsWith("audio/") && file.size <= 25 * 1024 * 1024
    })

    if (this.files.length + newFiles.length > 5) {
      alert("Максимум 5 файлов")
      return
    }

    this.files = [...this.files, ...newFiles]
    this.updateFileList()
    this.updateInput()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.updateFileList()
    this.updateInput()
  }

  updateFileList() {
    this.fileListTarget.innerHTML = this.files.map((file, index) => `
      <div class="flex items-center justify-between p-3 rounded-lg" style="background: var(--color-obsidian);">
        <div class="flex items-center">
          <svg class="w-5 h-5 mr-3" style="color: var(--color-neon-purple);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"/>
          </svg>
          <span style="color: var(--color-cloud);">${file.name}</span>
          <span class="ml-2 text-xs" style="color: var(--color-mist);">${this.formatSize(file.size)}</span>
        </div>
        <button type="button" data-action="click->file-upload#removeFile" data-index="${index}"
                class="p-1 rounded transition-colors" style="color: var(--color-coral);">
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

  formatSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / (1024 * 1024)).toFixed(1) + " MB"
  }
}
