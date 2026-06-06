import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    this.beforeCache = this.remove.bind(this)
    document.addEventListener("turbo:before-cache", this.beforeCache)

    this.timer = window.setTimeout(() => {
      this.dismiss()
    }, this.timeoutValue)
  }

  disconnect() {
    window.clearTimeout(this.timer)
    document.removeEventListener("turbo:before-cache", this.beforeCache)
  }

  dismiss() {
    this.element.classList.add("flash-dismissing")
    this.element.addEventListener("transitionend", this.remove.bind(this), { once: true })

    this.removeTimer = window.setTimeout(() => {
      this.remove()
    }, 240)
  }

  remove() {
    window.clearTimeout(this.removeTimer)
    this.element.remove()
  }
}
