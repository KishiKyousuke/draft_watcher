# 選手のドラフト候補年 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 選手が複数のドラフト候補年を持てるようにし、一覧の絞り込み・並び替え、詳細表示、新規登録/編集、CSVインポート/エクスポートに反映する。

**Architecture:** `Player` に対する子テーブル `player_draft_years`（`year` integer の複数行）を新設する。`Player` に仮想属性 `draft_years_text`（カンマ区切りテキスト）を追加し、フォーム・CSVの両方がこの一本の入口を経由して `player_draft_years` を作成/更新する。一覧の絞り込み・並び替えは `PlayersController#index` で `player_draft_years` を `LEFT JOIN`/`JOIN` して行う。

**Tech Stack:** Rails 8.0.3, SQLite3, RSpec 7.0 + FactoryBot + Shoulda Matchers, Hotwire(Turbo)/Tailwind CSS, Kaminari

**Spec:** `docs/superpowers/specs/2026-09-10-player-draft-years-design.md`

## Global Constraints

- ドラフト候補年は新規テーブル `player_draft_years`（`player_id`, `year`）で保持する。年のマスタテーブルは作らない。
- フォーム入力はカンマ区切りテキスト1本（`draft_years_text`）で複数年を受け付ける。動的な行追加UIやチェックボックス群は導入しない。
- CSVでは複数年をスラッシュ区切り（例: `2023/2024`）で1カラムに格納する。
- 一覧の絞り込みは単一選択セレクト。未選択（`すべて`）の場合は年で絞り込まない。
- 一覧では選手ごとに最新の候補年のみ表示し、選手一覧全体は「候補年が新しい選手が前」に来るよう並び替える。詳細画面では候補年をすべて表示する。
- 既存のコード規約に従う：enumはシンボル参照、CSVはUTF-8・日本語ヘッダー、`new.html.erb`/`edit.html.erb`は共有パーシャル化せず現状通り並行して編集する。

---

## Task 1: マイグレーションと `PlayerDraftYear` モデル

**Files:**
- Create: `db/migrate/<timestamp>_create_player_draft_years.rb`
- Create: `app/models/player_draft_year.rb`
- Test: `spec/models/player_draft_year_spec.rb`
- Modify: `config/locales/ja.yml`（`activerecord.models.player_draft_year`, `activerecord.attributes.player_draft_year.year` を追加）

**Interfaces:**
- Produces: `PlayerDraftYear` クラス（`belongs_to :player`, `year: Integer`）。テーブル `player_draft_years(player_id, year)`、`[player_id, year]` にユニークインデックス。

- [ ] **Step 1: 失敗するモデルスペックを書く**

`spec/models/player_draft_year_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerDraftYear, type: :model do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to validate_presence_of(:year) }
  it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than(1900) }

  describe 'uniqueness' do
    subject { build(:player_draft_year, player: create(:player)) }

    it { is_expected.to validate_uniqueness_of(:year).scoped_to(:player_id) }
  end
end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/models/player_draft_year_spec.rb`
Expected: FAIL（`PlayerDraftYear`が存在しない、または`player_draft_years`テーブルが存在しない旨のエラー）

- [ ] **Step 3: マイグレーションを生成する**

Run: `bin/rails generate migration CreatePlayerDraftYears`

生成されたファイル（`db/migrate/<timestamp>_create_player_draft_years.rb`）の中身を以下に置き換える：

```ruby
class CreatePlayerDraftYears < ActiveRecord::Migration[8.0]
  def change
    create_table :player_draft_years do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :year, null: false

      t.timestamps
    end
    add_index :player_draft_years, [:player_id, :year], unique: true
  end
end
```

- [ ] **Step 4: マイグレーションを実行する**

Run: `bin/rails db:migrate`
Expected: `player_draft_years`テーブルが作成され、`db/schema.rb`が更新される

- [ ] **Step 5: `PlayerDraftYear`モデルを作成する**

`app/models/player_draft_year.rb`:

```ruby
class PlayerDraftYear < ApplicationRecord
  belongs_to :player

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900 }
  validates :year, uniqueness: { scope: :player_id }
end
```

- [ ] **Step 6: FactoryBotのファクトリを追加する**

`spec/factories/player_draft_years.rb`（新規作成）:

```ruby
FactoryBot.define do
  factory :player_draft_year do
    association :player
    sequence(:year) { |n| 2020 + n }
  end
end
```

- [ ] **Step 7: i18nキーを追加する**

`config/locales/ja.yml` の `activerecord.models` に1行追加：

```yaml
      player_draft_year: ドラフト候補年
```

`activerecord.attributes` に以下を追加（`position:` ブロックの後、`pick:` ブロックの前などに配置）：

```yaml
      player_draft_year:
        year: 年
```

- [ ] **Step 8: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/models/player_draft_year_spec.rb`
Expected: PASS（全例が成功する）

- [ ] **Step 9: コミット**

```bash
git add db/migrate db/schema.rb app/models/player_draft_year.rb spec/models/player_draft_year_spec.rb spec/factories/player_draft_years.rb config/locales/ja.yml
git commit -m "feat: PlayerDraftYearモデルとマイグレーションを追加する"
```

---

## Task 2: `Player`モデルの拡張（`draft_years_text` / `latest_draft_year`）

**Files:**
- Modify: `app/models/player.rb`
- Create: `spec/models/player_spec.rb`
- Modify: `config/locales/ja.yml`（`activerecord.attributes.player.draft_years_text` を追加）

**Interfaces:**
- Consumes: `PlayerDraftYear`（Task 1）
- Produces: `Player#player_draft_years`（has_many）、`Player#draft_years_text`（String getter）、`Player#draft_years_text=(String)`（setter）、`Player#latest_draft_year`（Integer or nil）

- [ ] **Step 1: 失敗するモデルスペックを書く**

`spec/models/player_spec.rb`（新規作成）:

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do
  it { is_expected.to have_many(:player_draft_years).dependent(:destroy) }

  describe '#draft_years_text' do
    it '登録済みの候補年を新しい順にカンマ区切りで返す' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2025)

      expect(player.draft_years_text).to eq('2025, 2023')
    end

    it '候補年が未登録の場合は空文字を返す' do
      player = create(:player)

      expect(player.draft_years_text).to eq('')
    end
  end

  describe '#draft_years_text=' do
    it 'カンマ区切りの年から候補年を作成する' do
      player = create(:player)

      player.draft_years_text = '2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '既存の候補年のうち、入力に含まれないものは削除される' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2024)

      player.draft_years_text = '2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '重複する年は1つにまとめられる' do
      player = create(:player)

      player.draft_years_text = '2024, 2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '空文字を設定すると候補年がすべて削除される' do
      player = create(:player)
      player.player_draft_years.create!(year: 2024)

      player.draft_years_text = ''
      player.save!

      expect(player.reload.player_draft_years).to be_empty
    end
  end

  describe '#latest_draft_year' do
    it '最も新しい候補年を返す' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2025)

      expect(player.latest_draft_year).to eq(2025)
    end

    it '候補年が未登録の場合はnilを返す' do
      player = create(:player)

      expect(player.latest_draft_year).to be_nil
    end
  end
end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/models/player_spec.rb`
Expected: FAIL（`draft_years_text`等のメソッドが存在しない）

- [ ] **Step 3: `Player`モデルに実装を追加する**

`app/models/player.rb` の `has_many :player_positions, dependent: :destroy` の下に1行追加し、`pitching_batting`のenum定義の後（`confirmed_picks`メソッドの前）に以下を追加する：

```ruby
  has_many :player_draft_years, dependent: :destroy
```

```ruby
  # カンマ区切りの複数ドラフト候補年を返す・設定するための仮想属性
  def draft_years_text
    player_draft_years.order(year: :desc).pluck(:year).join(', ')
  end

  def draft_years_text=(text)
    years = text.to_s.split(',').map(&:strip).reject(&:blank?).map(&:to_i).uniq
    existing_by_year = player_draft_years.index_by(&:year)

    self.player_draft_years = years.map { |year| existing_by_year[year] || PlayerDraftYear.new(year: year) }
  end

  def latest_draft_year
    player_draft_years.maximum(:year)
  end
```

- [ ] **Step 4: i18nキーを追加する**

`config/locales/ja.yml` の `activerecord.attributes.player` ブロックに1行追加（`description:` の下など）：

```yaml
        draft_years_text: ドラフト候補年
```

- [ ] **Step 5: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/models/player_spec.rb`
Expected: PASS

- [ ] **Step 6: コミット**

```bash
git add app/models/player.rb spec/models/player_spec.rb config/locales/ja.yml
git commit -m "feat: Playerモデルにドラフト候補年の仮想属性を追加する"
```

---

## Task 3: `PlayersController#index` の絞り込み・並び替え

**Files:**
- Modify: `app/controllers/players_controller.rb:2-29`
- Create: `spec/requests/players_spec.rb`
- Modify: `config/locales/ja.yml`（`players.index.search.draft_year` を追加）

**Interfaces:**
- Consumes: `Player#player_draft_years`, `Player#draft_years_text=`, `Player#latest_draft_year`（Task 2）
- Produces: `PlayersController#index` の `@players`（`draft_year`で絞り込み・候補年新しい順にソート済み）、`@draft_years`（`Integer`の降順配列、絞り込みセレクトの選択肢に使用）

- [ ] **Step 1: 失敗するリクエストスペックを書く**

`spec/requests/players_spec.rb`（新規作成）:

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Players', type: :request do
  describe 'GET /players' do
    context 'ドラフト候補年での絞り込み' do
      it '指定した年の選手のみ表示する' do
        player_2024 = create(:player, name: '2024年候補')
        player_2024.draft_years_text = '2024'
        player_2024.save!

        player_2025 = create(:player, name: '2025年候補')
        player_2025.draft_years_text = '2025'
        player_2025.save!

        get players_path(draft_year: 2024)

        expect(response.body).to include('2024年候補')
        expect(response.body).not_to include('2025年候補')
      end

      it '年を未選択の場合は全選手を表示する' do
        player_2024 = create(:player, name: '2024年候補')
        player_2024.draft_years_text = '2024'
        player_2024.save!

        player_2025 = create(:player, name: '2025年候補')
        player_2025.draft_years_text = '2025'
        player_2025.save!

        get players_path

        expect(response.body).to include('2024年候補')
        expect(response.body).to include('2025年候補')
      end
    end

    context '並び替え' do
      it '候補年が新しい選手が前に来る（作成日時の新旧に関わらない）' do
        recent_year_but_created_first = create(:player, name: '選手A')
        recent_year_but_created_first.draft_years_text = '2025'
        recent_year_but_created_first.save!

        old_year_but_created_later = create(:player, name: '選手B')
        old_year_but_created_later.draft_years_text = '2020'
        old_year_but_created_later.save!

        get players_path

        body = response.body
        expect(body.index('選手A')).to be < body.index('選手B')
      end

      it '未指名のみフィルターと組み合わせてもエラーにならない' do
        team = create(:team)
        draft = create(:draft, year: 2025)

        drafted = create(:player, name: '指名済み選手')
        drafted.draft_years_text = '2025'
        drafted.save!
        create(:pick, player: drafted, draft: draft, team: team, confirmed: true)

        undrafted = create(:player, name: '未指名候補選手')
        undrafted.draft_years_text = '2024'
        undrafted.save!

        get players_path(undrafted_only: '1')

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('未指名候補選手')
        expect(response.body).not_to include('指名済み選手')
      end
    end
  end
end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: FAIL（`draft_year`パラメータが無視される、並び替えが作成日時のままになる）

- [ ] **Step 3: `PlayersController#index`を修正する**

`app/controllers/players_controller.rb:2-29` を以下に置き換える：

```ruby
  def index
    @players = Player.includes(:positions, :player_draft_years, picks: :draft)

    # 名前・ふりがな検索
    if params[:query].present?
      @players = @players.where('players.name LIKE ? OR players.name_kana LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
    end

    # カテゴリ検索
    if params[:category].present?
      @players = @players.where(category: params[:category])
    end

    # ポジション検索
    if params[:position_id].present?
      @players = @players.joins(:positions).where(positions: { id: params[:position_id] })
    end

    # ドラフト候補年検索
    if params[:draft_year].present?
      @players = @players.joins(:player_draft_years).where(player_draft_years: { year: params[:draft_year] })
    end

    # 未指名のみフィルター（本番ドラフトで確定した指名がない選手）
    if params[:undrafted_only] == '1'
      @players = @players.left_joins(picks: :draft)
                         .group('players.id')
                         .having('COUNT(CASE WHEN drafts.virtual = ? AND picks.confirmed = ? THEN 1 END) = 0', false, true)
    end

    @players = @players.left_joins(:player_draft_years)
                       .group('players.id')
                       .order(Arel.sql('MAX(player_draft_years.year) DESC, players.created_at DESC'))
                       .distinct
                       .page(params[:page]).per(50)
    @positions = Position.all
    @draft_years = PlayerDraftYear.distinct.order(year: :desc).pluck(:year)
  end
```

- [ ] **Step 4: i18nキーを追加する**

`config/locales/ja.yml` の `players.index.search` ブロックに1行追加（`position:` の下）：

```yaml
        draft_year: ドラフト候補年
```

- [ ] **Step 5: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: PASS

- [ ] **Step 6: 既存のリクエスト・サービス系テストが壊れていないことを確認する**

Run: `bundle exec rspec spec/requests spec/services`
Expected: PASS（全件成功）

- [ ] **Step 7: コミット**

```bash
git add app/controllers/players_controller.rb spec/requests/players_spec.rb config/locales/ja.yml
git commit -m "feat: 選手一覧でドラフト候補年による絞り込み・並び替えに対応する"
```

---

## Task 4: 一覧画面（`index.html.erb`）にフィルタと候補年列を追加

**Files:**
- Modify: `app/views/players/index.html.erb:17-41`（検索フォーム）
- Modify: `app/views/players/index.html.erb:64-148`（テーブル）
- Modify: `spec/requests/players_spec.rb`（表示内容のテストを追加）
- Modify: `config/locales/ja.yml`（`players.index.draft_year` を追加）

**Interfaces:**
- Consumes: `@draft_years`, `player.latest_draft_year`（Task 3, Task 2）

- [ ] **Step 1: 失敗するリクエストスペックを追加する**

`spec/requests/players_spec.rb` の `RSpec.describe 'Players'` ブロック内、`describe 'GET /players'` の中に新しい `context` を追加する：

```ruby
    context '表示' do
      it '絞り込みセレクトに「すべて」と登録済みの年が表示される' do
        player = create(:player)
        player.draft_years_text = '2024'
        player.save!

        get players_path

        expect(response.body).to include('すべて')
        expect(response.body).to include('name="draft_year"')
        expect(response.body).to include('2024')
      end

      it '一覧には最新の候補年のみ表示される' do
        player = create(:player, name: '複数年候補選手')
        player.draft_years_text = '2023, 2025'
        player.save!

        get players_path

        body = response.body
        expect(body.scan('2025').size).to be >= 1
        expect(body).not_to include('2023')
      end
    end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: FAIL（絞り込みセレクトも候補年列もまだ存在しない）

- [ ] **Step 3: 検索フォームにドラフト候補年セレクトを追加する**

`app/views/players/index.html.erb:17` の `<div class="grid grid-cols-1 md:grid-cols-3 gap-4">` を `<div class="grid grid-cols-1 md:grid-cols-4 gap-4">` に変更する。

`app/views/players/index.html.erb:33-40`（Position Searchブロックの直後、グリッドの閉じタグ`</div>`の直前）に以下を追加する：

```erb
          <!-- Draft Year Search -->
          <div>
            <%= form.label :draft_year, t('players.index.search.draft_year'), class: "block text-sm font-medium text-gray-700 mb-1" %>
            <%= form.select :draft_year,
                options_for_select([['すべて', '']] + @draft_years.map { |y| [y, y] }, params[:draft_year]),
                {},
                { class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-4 py-2 border" } %>
          </div>
```

- [ ] **Step 4: テーブルに候補年列を追加する**

`app/views/players/index.html.erb:72`（`<%= t('players.index.pick_result') %>`の`<th>`の直前）に以下を追加する：

```erb
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t('players.index.draft_year') %></th>
```

`app/views/players/index.html.erb:125`（指名結果の`<td>`ブロックの直前）に以下を追加する：

```erb
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <% if player.latest_draft_year %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      <%= player.latest_draft_year %><%= t('units.year') %>
                    </span>
                  <% end %>
                </td>
```

- [ ] **Step 5: i18nキーを追加する**

`config/locales/ja.yml` の `players.index` ブロックに1行追加（`pick_result:` の下）：

```yaml
      draft_year: 候補年
```

- [ ] **Step 6: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: PASS

- [ ] **Step 7: コミット**

```bash
git add app/views/players/index.html.erb spec/requests/players_spec.rb config/locales/ja.yml
git commit -m "feat: 選手一覧にドラフト候補年の絞り込みと表示列を追加する"
```

---

## Task 5: 詳細画面（`show.html.erb`）に全候補年を表示

**Files:**
- Modify: `app/views/players/show.html.erb:14-43`
- Modify: `spec/requests/players_spec.rb`

**Interfaces:**
- Consumes: `@player.player_draft_years`（Task 1, Task 2）

- [ ] **Step 1: 失敗するリクエストスペックを追加する**

`spec/requests/players_spec.rb` に新しい `describe` ブロックを追加する（末尾の `end`（`RSpec.describe`を閉じる行）の直前）：

```ruby

  describe 'GET /players/:id' do
    it '登録されている候補年をすべて新しい順に表示する' do
      player = create(:player)
      player.draft_years_text = '2023, 2025'
      player.save!

      get player_path(player)

      body = response.body
      expect(body.index('2025')).to be < body.index('2023')
    end

    it '候補年が未登録の場合は未登録と表示する' do
      player = create(:player)

      get player_path(player)

      expect(response.body).to include('未登録')
    end
  end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: FAIL（候補年の表示ブロックがまだ存在しない）

- [ ] **Step 3: 詳細ビューに候補年ブロックを追加する**

`app/views/players/show.html.erb:23-26`（ポジションの`dt`/`dd`ブロックの直後）に以下を追加する：

```erb
        <div>
          <dt class="text-sm font-medium text-gray-500"><%= t('activerecord.attributes.player.draft_years_text') %></dt>
          <dd class="mt-1 text-sm text-gray-900">
            <% if @player.player_draft_years.any? %>
              <div class="flex flex-wrap gap-1">
                <% @player.player_draft_years.order(year: :desc).each do |player_draft_year| %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    <%= player_draft_year.year %><%= t('units.year') %>
                  </span>
                <% end %>
              </div>
            <% else %>
              <span class="text-gray-400"><%= t('players.index.not_registered') %></span>
            <% end %>
          </dd>
        </div>
```

- [ ] **Step 4: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add app/views/players/show.html.erb spec/requests/players_spec.rb
git commit -m "feat: 選手詳細画面にドラフト候補年を全件表示する"
```

---

## Task 6: 新規登録・編集フォームでの候補年入力

**Files:**
- Modify: `app/controllers/players_controller.rb:75-77`（`player_params`）
- Modify: `app/views/players/new.html.erb:54-58`
- Modify: `app/views/players/edit.html.erb:54-58`
- Modify: `spec/requests/players_spec.rb`
- Modify: `config/locales/ja.yml`（`players.form.draft_years_text_hint` を追加）

**Interfaces:**
- Consumes: `Player#draft_years_text=`（Task 2）

- [ ] **Step 1: 失敗するリクエストスペックを追加する**

`spec/requests/players_spec.rb` の末尾（最後の`end`の直前）に追加する：

```ruby

  describe 'POST /players' do
    it 'カンマ区切りのドラフト候補年を登録できる' do
      post players_path, params: {
        player: {
          name: '田中太郎', name_kana: 'たなかたろう', category: 'high_school',
          draft_years_text: '2024, 2025'
        }
      }

      player = Player.last
      expect(player.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end
  end

  describe 'GET /players/:id/edit' do
    it '既存のドラフト候補年が入力欄に表示される' do
      player = create(:player)
      player.draft_years_text = '2023, 2024'
      player.save!

      get edit_player_path(player)

      expect(response.body).to include('value="2024, 2023"')
    end
  end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: FAIL（`draft_years_text`パラメータが許可されていない、入力欄も存在しない）

- [ ] **Step 3: `player_params`に`draft_years_text`を追加する**

`app/controllers/players_controller.rb:75-77` を以下に置き換える：

```ruby
  def player_params
    params.require(:player).permit(:name, :name_kana, :category, :affiliation, :pitching_batting, :height, :weight, :age, :description, :draft_years_text, position_ids: [])
  end
```

- [ ] **Step 4: `new.html.erb`にドラフト候補年の入力欄を追加する**

`app/views/players/new.html.erb:54-58`（Affiliationブロックの直後、Positionsブロックの直前）に以下を追加する：

```erb
        <!-- Draft Years -->
        <div>
          <%= form.label :draft_years_text, t('activerecord.attributes.player.draft_years_text'), class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= form.text_field :draft_years_text, placeholder: "2024, 2025", class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-4 py-2 border" %>
          <p class="mt-1 text-xs text-gray-500"><%= t('players.form.draft_years_text_hint') %></p>
        </div>
```

- [ ] **Step 5: `edit.html.erb`にも同じ入力欄を追加する**

`app/views/players/edit.html.erb:54-58`（同じ位置）に、Step 4と全く同じコードを追加する。

- [ ] **Step 6: i18nキーを追加する**

`config/locales/ja.yml` の `players.form` ブロックに1行追加（`select_prompt:` の下）：

```yaml
      draft_years_text_hint: "カンマ区切りで複数入力できます（例: 2024, 2025）"
```

- [ ] **Step 7: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/requests/players_spec.rb`
Expected: PASS

- [ ] **Step 8: コミット**

```bash
git add app/controllers/players_controller.rb app/views/players/new.html.erb app/views/players/edit.html.erb spec/requests/players_spec.rb config/locales/ja.yml
git commit -m "feat: 新規登録・編集画面でドラフト候補年を入力できるようにする"
```

---

## Task 7: CSVエクスポートへの対応

**Files:**
- Modify: `app/services/player_csv_exporter.rb`
- Create: `spec/services/player_csv_exporter_spec.rb`

**Interfaces:**
- Consumes: `player.player_draft_years`（Task 1, Task 2）
- Produces: `PlayerCsvExporter#generate` の出力CSVに「ドラフト候補年」列（スラッシュ区切り）が追加される

- [ ] **Step 1: 失敗するサービススペックを書く**

`spec/services/player_csv_exporter_spec.rb`（新規作成）:

```ruby
# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe PlayerCsvExporter, type: :service do
  describe '#generate' do
    it 'ドラフト候補年をスラッシュ区切りで出力する' do
      player = create(:player, name: '田中太郎')
      player.draft_years_text = '2023, 2024'
      player.save!

      exporter = PlayerCsvExporter.new(Player.where(id: player.id))
      parsed = CSV.parse(exporter.generate, headers: true)

      expect(parsed.first['ドラフト候補年']).to eq('2023/2024')
    end

    it '候補年が未登録の場合は空になる' do
      player = create(:player, name: '鈴木次郎')

      exporter = PlayerCsvExporter.new(Player.where(id: player.id))
      parsed = CSV.parse(exporter.generate, headers: true)

      expect(parsed.first['ドラフト候補年']).to be_blank
    end
  end
end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/services/player_csv_exporter_spec.rb`
Expected: FAIL（「ドラフト候補年」列が存在しない）

- [ ] **Step 3: `PlayerCsvExporter`を修正する**

`app/services/player_csv_exporter.rb` 全体を以下に置き換える：

```ruby
class PlayerCsvExporter
  require 'csv'

  def initialize(players = Player.includes(:positions, :player_draft_years).order(:id))
    @players = players
  end

  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers
      @players.each do |player|
        csv << row_for(player)
      end
    end
  end

  private

  def headers
    ['ID', 'カテゴリ', '名前', 'ふりがな', 'ポジション', '投打', '所属', '身長', '体重', '年齢', '寸評', 'ドラフト候補年']
  end

  def row_for(player)
    [
      player.id,
      translate_category(player.category),
      player.name,
      player.name_kana,
      format_positions(player.positions),
      translate_pitching_batting(player.pitching_batting),
      player.affiliation,
      player.height,
      player.weight,
      player.age,
      player.description,
      format_draft_years(player.player_draft_years)
    ]
  end

  def translate_category(category)
    return '' unless category
    I18n.t("activerecord.attributes.player.categories.#{category}")
  end

  def translate_pitching_batting(pitching_batting)
    return '' unless pitching_batting
    I18n.t("activerecord.attributes.player.pitching_battings.#{pitching_batting}")
  end

  def format_positions(positions)
    positions.map(&:short_name).join('/')
  end

  def format_draft_years(player_draft_years)
    player_draft_years.map(&:year).sort.join('/')
  end
end
```

- [ ] **Step 4: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/services/player_csv_exporter_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add app/services/player_csv_exporter.rb spec/services/player_csv_exporter_spec.rb
git commit -m "feat: CSVエクスポートにドラフト候補年列を追加する"
```

---

## Task 8: CSVインポートへの対応

**Files:**
- Modify: `app/services/player_csv_importer.rb`
- Create: `spec/services/player_csv_importer_spec.rb`

**Interfaces:**
- Consumes: `Player#draft_years_text=`（Task 2）
- Produces: `PlayerCsvImporter#import` が「ドラフト候補年」列（スラッシュ区切り）を読み取り、`player_draft_years`を作成する

- [ ] **Step 1: 失敗するサービススペックを書く**

`spec/services/player_csv_importer_spec.rb`（新規作成）:

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerCsvImporter, type: :service do
  describe '#import' do
    def csv_file_for(content)
      file = double('file')
      allow(file).to receive(:read).and_return(content.dup)
      file
    end

    it 'スラッシュ区切りのドラフト候補年を複数登録する' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,田中太郎,たなかたろう,,,東京高等学校,,,,,2023/2024
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be true
      expect(Player.last.player_draft_years.pluck(:year)).to contain_exactly(2023, 2024)
    end

    it 'ドラフト候補年が空の場合は登録しない' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,鈴木次郎,すずきじろう,,,大阪高等学校,,,,,
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be true
      expect(Player.last.player_draft_years).to be_empty
    end

    it '数値に変換できない値が含まれる場合はエラーになる' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,佐藤三郎,さとうさぶろう,,,福岡高等学校,,,,,2023/不正
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be false
      expect(importer.errors.first).to include('2行目')
      expect(importer.errors.first).to include('ドラフト候補年')
    end
  end
end
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bundle exec rspec spec/services/player_csv_importer_spec.rb`
Expected: FAIL（「ドラフト候補年」列が読み取られない）

- [ ] **Step 3: `PlayerCsvImporter`を修正する**

`app/services/player_csv_importer.rb` 全体を以下に置き換える：

```ruby
class PlayerCsvImporter
  require 'csv'

  class ImportError < StandardError; end

  attr_reader :errors, :imported_count

  def initialize(csv_file)
    @csv_file = csv_file
    @errors = []
    @imported_count = 0
    @positions_by_short_name = Position.all.index_by(&:short_name)
  end

  def import
    csv_text = @csv_file.read.force_encoding('UTF-8')
    csv = CSV.parse(csv_text, headers: true)

    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, index|
        line_number = index + 2 # ヘッダー行が1行目なので+2
        import_row(row, line_number)
      end
      @imported_count = csv.size
    end

    true
  rescue CSV::MalformedCSVError => e
    @errors << "CSVファイルの形式が正しくありません: #{e.message}"
    false
  rescue ImportError => e
    @errors << e.message
    false
  end

  private

  def import_row(row, line_number)
    category = convert_category(row['カテゴリ'], line_number)
    pitching_batting = convert_pitching_batting(row['投打'], line_number)
    position_ids = convert_positions(row['ポジション'], line_number)
    draft_years = convert_draft_years(row['ドラフト候補年'], line_number)

    player = Player.new(
      category: category,
      name: row['名前'],
      name_kana: row['ふりがな'],
      pitching_batting: pitching_batting,
      affiliation: row['所属'],
      height: row['身長'],
      weight: row['体重'],
      age: row['年齢'],
      description: row['寸評'],
      position_ids: position_ids,
      draft_years_text: draft_years.join(', ')
    )

    unless player.save
      error_messages = player.errors.full_messages.join(', ')
      raise ImportError, "#{line_number}行目: #{error_messages}"
    end
  end

  def convert_category(ja_text, line_number)
    return nil if ja_text.blank?

    category = find_enum_key_by_translation('player.categories', ja_text)
    raise ImportError, "#{line_number}行目: カテゴリは一覧にありません (値: #{ja_text})" if category.nil?

    category
  end

  def convert_pitching_batting(ja_text, line_number)
    return nil if ja_text.blank?

    pitching_batting = find_enum_key_by_translation('player.pitching_battings', ja_text)
    raise ImportError, "#{line_number}行目: 投打は一覧にありません (値: #{ja_text})" if pitching_batting.nil?

    pitching_batting
  end

  def find_enum_key_by_translation(i18n_scope, ja_text)
    translations = I18n.t("activerecord.attributes.#{i18n_scope}")
    translations.find { |key, value| value == ja_text }&.first&.to_s
  end

  def convert_positions(position_text, line_number)
    return [] if position_text.blank?

    position_short_names = position_text.split('/')
    position_ids = []

    position_short_names.each do |short_name|
      short_name = short_name.strip
      position = @positions_by_short_name[short_name]
      raise ImportError, "#{line_number}行目: ポジションが見つかりません (値: #{short_name})" if position.nil?

      position_ids << position.id
    end

    position_ids
  end

  def convert_draft_years(draft_year_text, line_number)
    return [] if draft_year_text.blank?

    draft_year_text.split('/').map do |year_text|
      year_text = year_text.strip
      unless year_text.match?(/\A\d+\z/)
        raise ImportError, "#{line_number}行目: ドラフト候補年の形式が正しくありません (値: #{year_text})"
      end

      year_text.to_i
    end
  end
end
```

- [ ] **Step 4: テストを実行して成功を確認する**

Run: `bundle exec rspec spec/services/player_csv_importer_spec.rb`
Expected: PASS

- [ ] **Step 5: 全体のテストスイートを実行する**

Run: `bundle exec rspec`
Expected: PASS（全件成功。既存のPick CSV関連テストも含め回帰がないことを確認する）

- [ ] **Step 6: RuboCopを実行する**

Run: `bundle exec rubocop app/models/player.rb app/models/player_draft_year.rb app/controllers/players_controller.rb app/services/player_csv_importer.rb app/services/player_csv_exporter.rb`
Expected: 違反なし（あれば`bundle exec rubocop -a`で自動修正し、再度確認する）

- [ ] **Step 7: コミット**

```bash
git add app/services/player_csv_importer.rb spec/services/player_csv_importer_spec.rb
git commit -m "feat: CSVインポートでドラフト候補年を登録できるようにする"
```

---

## 完了条件チェックリスト（issue#38との対応）

- [x] Task 3, 4: 選手一覧画面で、ドラフト候補年での絞り込みが行えること
- [x] Task 4, 5: 選手一覧・詳細画面に候補年情報が正しく表示されること（一覧=最新年のみ、詳細=全年）
- [x] Task 3: 選手一覧が候補年の新しい順に並ぶこと
- [x] Task 6: 新規登録・編集画面で候補年（複数）の登録ができること
- [x] Task 7, 8: CSVインポート・エクスポートで候補年情報を扱えること
