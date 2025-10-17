import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "selectedDisplay", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    const query = this.inputTarget.value

    if (query.length < 1) {
      this.resultsTarget.innerHTML = ""
      return
    }

    this.timeout = setTimeout(() => {
      const url = `${this.urlValue}?query=${encodeURIComponent(query)}`

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
