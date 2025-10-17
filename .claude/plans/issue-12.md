# Issue #12: 指名作成・編集画面に選手検索機能を追加

## 概要

現在、指名作成は選手詳細から行うようになっており、指名作成画面では選手は固定される。しかし、UXを考えると指名作成はドラフト詳細画面から行えた方が良い。そうなると、指名作成画面から選手を選択する必要があり、その際に選手の検索が行えないと不便であるため、選手を検索できるセレクトボックスを実装する。

## 要件

- 指名作成画面から選手の選択を行えるようにする
- 選手を選択するセレクトボックスでインクリメンタルサーチを行えるようにする
- Hotwireを使って実装する

## 完了条件

- [ ] 指名作成・編集画面で、選手の指定・変更が行えること
- [ ] 指名作成・編集画面の選手選択セレクトボックスでインクリメンタルサーチが行えること
- [ ] 上記の操作を行った上で、指名作成ができること

## 現状分析

### 現在の実装

- `app/controllers/picks_controller.rb:6-11` - newアクションでplayer_idを必須パラメータとして受け取る
- `app/views/picks/new.html.erb:33-41` - 選手情報を固定表示（hidden_field）
- `app/views/picks/edit.html.erb:33-41` - 選手情報を固定表示（hidden_field）
- 選手詳細ページから指名作成画面に遷移する導線

### 問題点

1. 指名作成画面で選手を選択・変更できない
2. ドラフト詳細画面から直接指名を作成する導線がない
3. 選手リストから検索して選択する機能がない

## 実装計画

### 1. 選手検索APIエンドポイントの作成

**ファイル**: `app/controllers/players/searches_controller.rb`

```ruby
class Players::SearchesController < ApplicationController
  def index
    @players = if params[:query].present?
                 Player.where("name LIKE ? OR name_kana LIKE ?",
                             "%#{params[:query]}%",
                             "%#{params[:query]}%")
                       .order(:name_kana)
                       .limit(20)
               else
                 Player.none
               end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @players }
    end
  end
end
```

**ビュー**: `app/views/players/searches/index.turbo_stream.erb`

```erb
<%= turbo_stream.update "player-search-results" do %>
  <% if @players.any? %>
    <ul class="mt-2 border border-gray-300 rounded-md max-h-60 overflow-y-auto bg-white shadow-lg">
      <% @players.each do |player| %>
        <li class="px-4 py-2 hover:bg-blue-50 cursor-pointer border-b last:border-b-0"
            data-action="click->player-search#selectPlayer"
            data-player-id="<%= player.id %>"
            data-player-name="<%= player.name %>"
            data-player-kana="<%= player.name_kana %>">
          <span class="font-medium"><%= player.name %></span>
          <span class="text-gray-500 text-sm ml-2">(<%= player.name_kana %>)</span>
        </li>
      <% end %>
    </ul>
  <% elsif params[:query].present? %>
    <div class="mt-2 p-4 text-sm text-gray-500 border border-gray-300 rounded-md bg-gray-50">
      該当する選手が見つかりませんでした
    </div>
  <% end %>
<% end %>
```

### 2. Stimulus Controllerの実装

**ファイル**: `app/javascript/controllers/player_search_controller.js`

```javascript
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
```

### 3. ビューの更新

**ファイル**: `app/views/picks/new.html.erb` および `edit.html.erb`

選手フィールド部分（33-41行目）を以下に置き換え：

```erb
<!-- Player Search -->
<div data-controller="player-search"
     data-player-search-url-value="<%= players_searches_path %>">
  <%= form.label :player_id, Pick.human_attribute_name(:player), class: "block text-sm font-medium text-gray-700 mb-1" %>

  <!-- 選択された選手の表示 -->
  <div id="selected-player"
       data-player-search-target="selectedDisplay"
       class="mt-1 p-3 bg-gray-50 rounded-md border border-gray-300">
    <% if @selected_player %>
      <span class="text-sm font-medium text-gray-900"><%= @selected_player.name %></span>
      <span class="text-sm text-gray-500 ml-2">(<%= @selected_player.name_kana %>)</span>
    <% else %>
      <span class="text-sm text-gray-500">選手を検索して選択してください</span>
    <% end %>
  </div>

  <%= form.hidden_field :player_id,
                        data: { player_search_target: "hiddenField" },
                        value: @pick.player_id %>

  <!-- 検索入力フィールド -->
  <div class="mt-2">
    <input type="text"
           placeholder="選手名またはふりがなで検索"
           data-player-search-target="input"
           data-action="input->player-search#search"
           class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-4 py-2 border">
  </div>

  <!-- 検索結果表示エリア -->
  <div id="player-search-results"
       data-player-search-target="results">
  </div>
</div>
```

### 4. PicksControllerの更新

**ファイル**: `app/controllers/picks_controller.rb`

```ruby
def new
  @pick = Pick.new
  @pick.player_id = params[:player_id] if params[:player_id].present?
  @selected_player = Player.find(params[:player_id]) if params[:player_id].present?
  @teams = Team.all
end

def create
  @pick = Pick.new(pick_params)

  if @pick.save
    redirect_to player_path(@pick.player), notice: t('notices.pick_created')
  else
    @selected_player = Player.find(@pick.player_id) if @pick.player_id.present?
    @teams = Team.all
    render :new, status: :unprocessable_entity
  end
end

def edit
  @pick = Pick.find(params[:id])
  @selected_player = @pick.player
  @teams = Team.all
end

def update
  @pick = Pick.find(params[:id])
  if @pick.update(pick_params)
    redirect_to picks_path, notice: t('notices.pick_updated')
  else
    @selected_player = @pick.player if @pick.player_id.present?
    @teams = Team.all
    render :edit, status: :unprocessable_entity
  end
end
```

### 5. ルーティングの追加

**ファイル**: `config/routes.rb`

```ruby
namespace :players do
  resource :import, only: [:new, :create]
  resource :export, only: [:new, :create]
  resources :searches, only: [:index]  # 追加
end
```

## 技術的な補足

### Hotwireの活用

- **Turbo Streams**: 検索結果を部分的に更新
- **Stimulus**: フロントエンドのインタラクション管理
- デバウンス処理で不要なリクエストを削減

### パフォーマンス考慮

- 検索結果は最大20件に制限
- インクリメンタルサーチは1文字以上入力時に実行
- 300msのデバウンスで連続入力を処理

### UX改善ポイント

1. 検索フィールドで即座に候補が表示される
2. 選択した選手が明確に表示される
3. 既存の選手がいる場合はそのまま表示
4. エラー時に選手情報を保持

## テスト項目

- [ ] 選手名で検索できること
- [ ] ふりがなで検索できること
- [ ] 検索結果から選手を選択できること
- [ ] 選択した選手で指名を作成できること
- [ ] 編集画面で選手を変更できること
- [ ] 検索結果が0件の場合、適切なメッセージが表示されること
- [ ] デバウンスが正しく機能すること

## 関連Issue

- Issue #12: https://github.com/KishiKyousuke/draft_watcher/issues/12
