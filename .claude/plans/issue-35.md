# Issue #35: 選手の指名結果のCSVエクスポート・インポート機能の実装

## 概要
**タイトル:** [機能] 選手の指名結果のCSVエクスポート・インポート機能の実装

**目的:** 現在は選手情報のCSV入出力機能のみが存在し、ドラフト指名後のデータをCSVで管理できない。この機能により、過去にCSVで作成された指名情報を取り込むことが可能になる。

## 現状分析

### 既存の実装パターン
- 選手データのCSV機能が既に実装済み
  - サービス層: `PlayerCsvImporter`, `PlayerCsvExporter`
  - コントローラー: `Player::ImportsController`, `Player::ExportsController`
  - ルーティング: `namespace :player` でリソース定義
  - ビュー: `app/views/player/imports/new.html.erb`, `app/views/player/exports/new.html.erb`

### Pickモデルの構造
- 関連: `belongs_to :player, :team, :draft`
- 主要属性:
  - `draft_id`: ドラフトID
  - `player_id`: 選手ID
  - `team_id`: 球団ID
  - `draft_round`: 指名順位（整数、1以上）
  - `training_player`: 育成指名フラグ（boolean）
  - `confirmed`: 指名確定フラグ（boolean、1位支配下のみデフォルトfalse）
  - `final_pick`: 最終指名フラグ（boolean）
- バリデーション:
  - 同一ドラフト内での選手の重複指名を禁止（1位支配下の抽選は例外）

### エクスポートすべき情報
- ドラフト年（`draft.year`）
- 選手名（`player.name`）
- ポジション（`player.positions` - スラッシュ区切り）
- 所属（`player.affiliation`）
- 指名球団（`team.name`）
- 指名順位（`draft_round`）
- 育成かどうか（`training_player`）
- 指名確定かどうか（`confirmed`）
- 最終指名かどうか（`final_pick`）

## 実装計画

### 1. サービスクラスの作成

#### `app/services/pick_csv_exporter.rb`
- 既存の`PlayerCsvExporter`を参考に実装
- CSVヘッダー: `['ID', 'ドラフト年', '選手名', 'ポジション', '所属', '指名球団', '指名順位', '育成', '確定', '最終指名']`
- データ取得: `Pick.includes(:player, :team, :draft, player: :positions)`でN+1を回避
- boolean値の日本語変換: 「はい」/「いいえ」または「○」/「×」
- ポジションのフォーマット: `player.positions.map(&:short_name).join('/')`

#### `app/services/pick_csv_importer.rb`
- 既存の`PlayerCsvImporter`を参考に実装
- CSVカラム: ドラフト年、選手名、ポジション、所属、指名球団、指名順位、育成、確定、最終指名
- 選手の検索:
  - 選手名で検索（完全一致）
  - 見つからない場合はエラー
  - 複数見つかった場合は所属も併せて検索
- 球団の検索:
  - 球団名で検索（完全一致）
  - 見つからない場合はエラー
- ドラフトの検索/作成:
  - 年度で検索
  - 見つからない場合は新規作成
- boolean値の変換: 「はい」「○」「true」→ true、「いいえ」「×」「false」または空→ false
- トランザクション処理とエラー報告（行番号付き）

### 2. コントローラーの作成

#### `app/controllers/pick/imports_controller.rb`
- 名前空間: `Pick`
- アクション: `new`, `create`
- `create`アクション:
  - ファイルの存在確認
  - `PickCsvImporter`を呼び出し
  - 成功時: `picks_path`へリダイレクト、件数を通知
  - 失敗時: `new_pick_import_path`へリダイレクト、エラー表示

#### `app/controllers/pick/exports_controller.rb`
- 名前空間: `Pick`
- アクション: `new`, `create`
- `create`アクション:
  - `PickCsvExporter`を呼び出し
  - ファイル名: `picks_YYYYMMDD_HHMMSS.csv`
  - `send_data`でダウンロード

### 3. ルーティングの追加

#### `config/routes.rb`
- 以下を追加:
```ruby
namespace :pick do
  resource :import, only: [:new, :create]
  resource :export, only: [:new, :create]
end
```

### 4. ビューの作成

#### `app/views/pick/imports/new.html.erb`
- 既存の`app/views/player/imports/new.html.erb`を参考
- CSVフォーマット説明セクション
- サンプルCSV表示
- ファイルアップロードフォーム
- キャンセルボタン（`picks_path`へ）

#### `app/views/pick/exports/new.html.erb`
- 既存の`app/views/player/exports/new.html.erb`を参考
- エクスポート説明
- エクスポートボタン（フォーム送信）
- キャンセルボタン（`picks_path`へ）

### 5. ヘッダー導線の追加

#### `app/views/layouts/application.html.erb`
- ナビゲーションメニューの追加が必要
- 現状はヘッダーメニューが存在しないため、新規作成が必要
- 追加項目:
  - 選手一覧
  - 指名一覧
  - ドラフト一覧
  - CSV操作（ドロップダウン）
    - 選手インポート
    - 選手エクスポート
    - 指名インポート（新規）
    - 指名エクスポート（新規）

### 6. 国際化（I18n）

#### `config/locales/ja.yml`
- 以下の翻訳を追加:
  - `activerecord.models.pick`
  - `activerecord.attributes.pick.*`
  - `notices.picks_imported`
  - `errors.pick_import_*`
- boolean値の翻訳（必要に応じて）

## テスト項目

- [ ] 正しい形式のCSVから指名データをインポートできる
- [ ] 既存の選手名を使って指名を作成できる
- [ ] 既存の球団名を使って指名を作成できる
- [ ] 存在しないドラフト年の場合、新規ドラフトが作成される
- [ ] boolean値（育成、確定、最終指名）が正しく変換される
- [ ] 不正なデータでエラーメッセージが表示される（行番号付き）
- [ ] 選手が見つからない場合にエラーが表示される
- [ ] 球団が見つからない場合にエラーが表示される
- [ ] CSVエクスポートで全指名情報が出力される
- [ ] エクスポートしたCSVを再インポートできる（往復テスト）
- [ ] ポジションがスラッシュ区切りで正しく表示される
- [ ] ヘッダーのリンクから各ページへ遷移できる
- [ ] エクスポートしたファイル名に日時が含まれる

## 実装時の注意点

### データ整合性
- Pickモデルのバリデーションを尊重する
  - 同一ドラフト内での選手の重複指名チェック
  - 1位指名の支配下は抽選のため重複可能
- トランザクション処理で全件成功/全件失敗を保証

### パフォーマンス
- N+1クエリを避けるため、必ず`includes`を使用
- エクスポート時: `Pick.includes(:player, :team, :draft, player: :positions)`
- インポート前に関連データを事前読み込み（選手、球団マップ）

### エラーハンドリング
- CSVパースエラーのキャッチ
- 各行のエラーを行番号付きで収集
- ユーザーフレンドリーなエラーメッセージ（日本語）

### 既存パターンの踏襲
- `PlayerCsvImporter/Exporter`と同じ構造を維持
- エラーハンドリングパターンを統一
- ビューのスタイルとレイアウトを統一（Tailwind CSS）

### CSVフォーマット
- UTF-8エンコーディング必須
- 日本語ヘッダー使用
- boolean値は「はい」/「いいえ」で統一

### 選手と球団の検索
- 選手名は完全一致で検索（あいまい検索は不要）
- 複数候補がある場合は所属も照合
- 球団名は完全一致（12球団固定のため）

### ドラフトの自動作成
- CSVインポート時に存在しないドラフト年の場合、自動的に新規作成
- デフォルト値:
  - `starts_with_central`: true
  - `virtual`: false
