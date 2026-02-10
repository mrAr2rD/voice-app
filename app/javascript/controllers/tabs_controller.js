import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "panel"]

  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab

    // Update nav buttons
    this.navTarget.querySelectorAll(".tab-button").forEach(button => {
      if (button.dataset.tab === tab) {
        button.classList.add("border-indigo-500", "text-indigo-600")
        button.classList.remove("border-transparent", "text-gray-500")
      } else {
        button.classList.remove("border-indigo-500", "text-indigo-600")
        button.classList.add("border-transparent", "text-gray-500")
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tab === tab) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
