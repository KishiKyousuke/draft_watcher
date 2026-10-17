import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "selectedDisplay", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null

    // ドラフトが切り替わったら、その年度の候補選手で検索し直す
    this.search = this.search.bind(this)
    this.draftSelect = this.element.closest("form")?.querySelector("[name='pick[draft_id]']")
    this.draftSelect?.addEventListener("change", this.search)
  }

  disconnect() {
    this.draftSelect?.removeEventListener("change", this.search)
  }

  search() {
    clearTimeout(this.timeout)

    const query = this.inputTarget.value

    if (query.length < 1) {
      this.resultsTarget.innerHTML = ""
      return
    }

    this.timeout = setTimeout(() => {
      const params = new URLSearchParams({ query })
      if (this.draftSelect?.value) params.append("draft_id", this.draftSelect.value)
      const url = `${this.urlValue}?${params}`

      fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
    }, 300) // 300msのデバウンス
  }

  selectPlayer(event) {
    const playerId = event.currentTarget.dataset.playerId
    const playerName = event.currentTarget.dataset.playerName
    const playerKana = event.currentTarget.dataset.playerKana

    // Hidden fieldに選手IDをセット
    this.hiddenFieldTarget.value = playerId

    // 選択された選手を表示
    this.selectedDisplayTarget.innerHTML = `
      <span class="font-medium">${playerName}</span>
      <span class="text-gray-500 ml-2">(${playerKana})</span>
    `

    // 検索フィールドをクリア
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  clearSelection() {
    this.hiddenFieldTarget.value = ""
    this.selectedDisplayTarget.innerHTML = ""
  }
}
