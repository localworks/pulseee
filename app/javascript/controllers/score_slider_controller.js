import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "range", "value"]

  connect() {
    this.form = this.element.closest("form")
    this.validateBeforeSubmit = this.validateBeforeSubmit.bind(this)
    this.form?.addEventListener("submit", this.validateBeforeSubmit)

    const selectedValue = this.inputTarget.value

    if (selectedValue) {
      this.markSelected(selectedValue)
    } else {
      this.markUnselected()
    }
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.validateBeforeSubmit)
  }

  select() {
    const selectedValue = this.rangeTarget.value

    this.markSelected(selectedValue)
  }

  validateBeforeSubmit(event) {
    if (this.inputTarget.value) return

    this.markUnselected()
    event.preventDefault()
    this.rangeTarget.reportValidity()
  }

  markSelected(selectedValue) {
    this.rangeTarget.value = selectedValue
    this.inputTarget.value = selectedValue
    this.valueTarget.textContent = selectedValue
    this.element.classList.add("is-selected")
    this.rangeTarget.setCustomValidity("")
    this.rangeTarget.setAttribute("aria-valuetext", `${selectedValue} / ${this.rangeTarget.max}`)
  }

  markUnselected() {
    this.inputTarget.value = ""
    this.valueTarget.textContent = "未選択"
    this.element.classList.remove("is-selected")
    this.rangeTarget.setCustomValidity("すべての設問に回答してください")
    this.rangeTarget.setAttribute("aria-valuetext", "未選択")
  }
}
