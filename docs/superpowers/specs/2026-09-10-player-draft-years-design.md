# 選手のドラフト候補年 設計書

- 対象issue: #38 [機能] 選手にドラフト候補年の情報を持たせられるようにする
- 作成日: 2026-09-10

## 背景・目的

各選手がドラフト候補となった年の情報を持つことで、各年のドラフト候補で絞り込めるようにする。指名漏れ（あるドラフトで指名されず、翌年以降も候補となり続ける）を考慮し、選手は複数のドラフト候補年を持てる必要がある。

## 要件（issue#38より）

- 選手がドラフト候補となった年の情報を持てること
- 指名漏れの可能性を考慮し、複数の年を持てること
- 選手一覧画面で各年での絞り込みができること
- 選手一覧・詳細画面に候補年の情報を表示できること（一覧=最新年のみ、詳細=候補となった年を全て）
- 選手一覧画面では最新年の候補選手が前に来ること
- 選手新規登録・編集画面でドラフト候補年の登録ができること
- CSVインポート・エクスポートでドラフト候補年の登録ができること

## 全体方針

既存の `Position`/`PlayerPosition` は固定マスタからの多対多選択だが、ドラフト候補年は固定マスタを持たない自由な整数値の複数登録が必要という点で性質が異なる。そのため以下の方針を取る。

- ドラフト候補年は新規テーブル `player_draft_years` で `Player` の子レコードとして保持する（マスタテーブルは作らない）
- フォーム・CSVでは「カンマ区切り／スラッシュ区切りのテキスト」として複数年を一括で扱う。動的な行追加UIやチェックボックス群のような追加UI部品は導入しない（YAGNI）
- 一覧の絞り込みは単一選択（既存のカテゴリ・ポジション検索と同じUIパターン）とし、「すべて」を選ぶと年で絞り込まない

## データモデル

### マイグレーション

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

### モデル

`PlayerDraftYear`
- `belongs_to :player`
- `validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900 }`
- `validates :year, uniqueness: { scope: :player_id }`

`Player`（追加分のみ）
- `has_many :player_draft_years, dependent: :destroy`
- 仮想属性 `draft_years_text`
  - getter: `player_draft_years.order(year: :desc).pluck(:year).join(', ')`
  - setter: カンマ区切りテキストをパースして整数配列（重複排除）にし、`self.player_draft_years = [...]` で一括置換する。既存レコードは年が一致すれば流用し、消えた年は自動的にdestroyされる（autosave associationの標準挙動）
- `latest_draft_year`: `player_draft_years.maximum(:year)`（一覧のソート・表示で使用）

不正な年フォーマット（数値に変換できない文字列など）は `draft_years_text=` 内でスキップせず、`Player` の `errors.add(:draft_years_text, ...)` で通常のバリデーションエラーとして扱う。

## コントローラ（PlayersController#index）

```ruby
@players = Player.includes(:positions, :player_draft_years, picks: :draft)

# ドラフト候補年での絞り込み（単一選択、未選択時は絞り込まない）
if params[:draft_year].present?
  @players = @players.joins(:player_draft_years).where(player_draft_years: { year: params[:draft_year] })
end

# ...既存のquery/category/position/undrafted_onlyフィルタは変更なし...

@players = @players.left_joins(:player_draft_years)
                    .group('players.id')
                    .order(Arel.sql('MAX(player_draft_years.year) DESC, players.created_at DESC'))
                    .distinct
                    .page(params[:page]).per(50)

@draft_years = PlayerDraftYear.distinct.order(year: :desc).pluck(:year)
```

要件「選手一覧画面では最新年の候補選手が前に来る」を満たすため、`MAX(player_draft_years.year) DESC` を第一ソートキーとする。候補年未登録の選手は `LEFT JOIN` によりNULLとなり、降順ソートでは最後に回る（SQLite標準の挙動）。

**実装時の注意点**: 既存の `undrafted_only` フィルターも `.group('players.id')` と `.having(...)` を使っている。同一クエリ内で `player_draft_years` の集計（`MAX(year)`）と `picks`/`drafts` の集計（`having` 条件）が衝突しないか、実装時に実際のSQLを確認すること。問題が出る場合は、`draft_year` 最大値の取得をサブクエリ化する対応に切り替える。

## ビュー

### 一覧（`app/views/players/index.html.erb`）

- 検索フォームに「ドラフト候補年」の `select` を追加。既存のカテゴリ検索と同じ `options_for_select([['すべて', '']] + @draft_years.map { |y| [y, y] }, params[:draft_year])` パターン
- テーブルに「候補年」列を追加し、`player.latest_draft_year` のみバッジ表示

### 詳細（`app/views/players/show.html.erb`）

- 基本情報の `dl` に「ドラフト候補年」行を追加し、`player.player_draft_years.order(year: :desc)` の全年をバッジ表示

### 新規登録・編集（`app/views/players/new.html.erb`, `edit.html.erb`）

- `form.text_field :draft_years_text` を追加。ラベル「ドラフト候補年（カンマ区切りで複数入力可、例: 2024, 2025）」
- `player_params` に `:draft_years_text` を追加

## CSVインポート/エクスポート

### エクスポート（`PlayerCsvExporter`）

- ヘッダーに「ドラフト候補年」を追加
- 値: `player.player_draft_years.order(:year).pluck(:year).join('/')`（例: `2023/2024`）
- `initialize` の `includes` に `:player_draft_years` を追加

### インポート（`PlayerCsvImporter`）

- `convert_draft_years(row['ドラフト候補年'], line_number)` を追加。`/` 区切りで分割し、各要素を整数変換。数値変換できない値があれば `ImportError` で `"#{line_number}行目: ドラフト候補年の形式が正しくありません (値: ...)"` を送出
- `Player.new(...)` の呼び出しに `draft_years_text: converted_years.join(', ')` を渡す（内部的には既存の `draft_years_text=` セッターを再利用する）

## i18n（`config/locales/ja.yml`）

- `activerecord.models.player_draft_year`
- `activerecord.attributes.player_draft_year.year`
- `activerecord.attributes.player.draft_years_text`
- `players.index.search.draft_year`
- `players.form.draft_years_text_hint`（カンマ区切り入力のヘルプテキスト）

## テスト方針

- モデル: `PlayerDraftYear` のバリデーション（presence, numericality, `player_id`+`year` のuniqueness）
- モデル: `Player#draft_years_text` のgetter/setter（追加・削除・重複排除・空文字・不正値時の挙動）
- コントローラ: `draft_year` 絞り込み、最新年降順ソート、`undrafted_only` との併用
- サービス: `PlayerCsvExporter`/`PlayerCsvImporter` の新カラム対応（正常系・不正フォーマットのエラー行番号）
- システムテスト: 一覧の年フィルター、新規登録での複数年入力、詳細画面での全年表示

## スコープ外

- 動的な行追加UI（JS）
- 複数選択の年フィルター
- 年マスタテーブルの導入
