import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]

  connect() {
    this.hide({ immediate: true })
  }

  show(event) {
    this.hide({ immediate: true })

    const tooltip = this.tooltipTargets.find((target) => target.dataset.week === event.currentTarget.dataset.week)
    if (!tooltip) return

    tooltip.hidden = false
    requestAnimationFrame(() => tooltip.classList.add("is-visible"))
  }

  hide({ immediate = false } = {}) {
    this.tooltipTargets.forEach((tooltip) => {
      window.clearTimeout(tooltip.hideTimeout)
      tooltip.classList.remove("is-visible")

      if (immediate) {
        tooltip.hidden = true
      } else {
        tooltip.hideTimeout = window.setTimeout(() => { tooltip.hidden = true }, 160)
      }
    })
  }
}
