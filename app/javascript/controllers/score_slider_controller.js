import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "range", "value"]

  connect() {
    const selectedValue = this.inputTarget.value

    if (selectedValue) {
      this.rangeTarget.value = selectedValue
      this.valueTarget.textContent = selectedValue
      this.element.classList.add("is-selected")
      this.rangeTarget.setCustomValidity("")
      this.rangeTarget.setAttribute("aria-valuetext", `${selectedValue} / 10`)
    } else {
      this.valueTarget.textContent = "未選択"
      this.element.classList.remove("is-selected")
      this.rangeTarget.setCustomValidity("評価を選択してください")
      this.rangeTarget.setAttribute("aria-valuetext", "未選択")
    }
  }

  select() {
    const selectedValue = this.rangeTarget.value

    this.inputTarget.value = selectedValue
    this.valueTarget.textContent = selectedValue
    this.element.classList.add("is-selected")
    this.rangeTarget.setCustomValidity("")
    this.rangeTarget.setAttribute("aria-valuetext", `${selectedValue} / 10`)
  }
}
