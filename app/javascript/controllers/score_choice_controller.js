import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.syncStatuses()
  }

  select(event) {
    this.markAnswered(event.target.dataset.questionId)
    this.markSelectedChoice(event.target)
  }

  syncStatuses() {
    this.element.querySelectorAll(".score-choice-input:checked").forEach((input) => {
      this.markAnswered(input.dataset.questionId)
      this.markSelectedChoice(input)
    })
  }

  markAnswered(questionId) {
    this.statusTargets
      .filter((status) => status.dataset.questionId === questionId)
      .forEach((status) => status.classList.add("is-answered"))
  }

  markSelectedChoice(input) {
    this.element
      .querySelectorAll(`.score-choice-input[name="${CSS.escape(input.name)}"]`)
      .forEach((radio) => {
        radio.closest(".score-choice")?.classList.toggle("is-selected", radio.checked)
      })
  }
}
