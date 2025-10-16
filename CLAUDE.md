# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Draft Watcherは、NPB（日本プロ野球）のドラフト会議に関するデータを管理するRails 8アプリケーションです。ドラフト候補選手、指名結果、球団、関連情報を日本語で管理します。

## 開発コマンド

### セットアップ
```bash
bundle install
rails db:create
rails db:migrate
rails db:seed
```

### アプリケーション起動
```bash
rails server
# http://localhost:3000 でアクセス
```

### データベース操作
```bash
# データベース作成とセットアップ
rails db:setup

# データベースリセット（drop, create, migrate, seed）
rails db:reset

# マイグレーション実行
rails db:migrate

# 直前のマイグレーションをロールバック
rails db:rollback
```

### テスト実行
```bash
# 全テスト実行
rails test

# 特定のテストファイルを実行
rails test test/models/player_test.rb

# 特定の行番号のテストを実行
rails test test/models/player_test.rb:10

# システムテスト実行
rails test:system
```

### コード品質チェック
```bash
# RuboCop実行
bundle exec rubocop

# RuboCop自動修正
bundle exec rubocop -a

# Brakemanセキュリティスキャン実行
bundle exec brakeman
```

### アセット管理
```bash
# Tailwind CSSビルド
rails tailwindcss:build

# Tailwind CSS変更監視
rails tailwindcss:watch
```

## アーキテクチャ

### コアモデル

**Player（選手）**
- ドラフト候補選手の中心モデル
- Positionと多対多関係（`player_positions`中間テーブル経由）
- Pickと1対多関係（指名結果）
- Enum: `category`（高校生、大学生、社会人、独立、その他）、`pitching_batting`（投打の6パターン）

**Pick（指名結果）**
- ドラフト指名を記録
- PlayerとTeamに紐づく
- 育成指名と支配下指名を区別（`training_player`フラグ）
- 1位指名の確定状態を管理（`confirmed`フラグ）
- 最終指名フラグ（`final_pick`）
- バリデーション: 同一年度での同一選手の重複指名を防止（1位指名の支配下は抽選のため例外）

**Team（球団）**
- NPB球団マスタデータ（12球団）
- Enum: `league`（セ・リーグ: 0、パ・リーグ: 1）
- 2025年順位順でシードされる

**Position（ポジション）**
- 選手ポジションのマスタデータ（9ポジション: 投/捕/一/二/三/遊/左/中/右）
- `short_name`で表示とCSV操作に使用

**PlayerPosition（中間テーブル）**
- PlayerとPositionの多対多関係を管理

**Draft（ドラフト会議）**
- 年度ごとのドラフト会議を表現
- `starts_with_central`: どちらのリーグが先に指名するかのフラグ
- `virtual`: シミュレーション/練習用ドラフトのフラグ

**TeamStanding（チーム順位）**
- 特定ドラフトにおけるチームの順位を記録
- ドラフト順を決定
- draft_id + team_idにユニーク制約

### サービス層

ビジネスロジックはコントローラーから分離してサービスクラスに実装：

**PlayerCsvImporter**（`app/services/player_csv_importer.rb`）
- 日本語カラムヘッダーでのCSVインポート
- I18nを使用した日本語enum値のバリデーションと変換
- N+1クエリ回避のためPositionレコードを事前読み込み
- トランザクションベースで行ごとのエラー報告
- エラー形式: 「{行番号}行目: {エラーメッセージ}」

**PlayerCsvExporter**（`app/services/player_csv_exporter.rb`）
- 日本語ヘッダーで選手データをCSVエクスポート
- enum値の翻訳にI18nを使用
- ポジションデータをスラッシュ区切りの略称でフォーマット

### 国際化（I18n）

アプリケーションは完全に日本語化されています：
- プライマリロケール: `ja`（`config/locales/ja.yml`）
- すべてのモデル属性、enum、エラーメッセージが日本語
- CSVインポート/エクスポートは日本語ヘッダーと値を使用

### コントローラー

**PlayersController**
- ドラフト候補選手のRESTful CRUD
- ページネーション: 1ページ50件（Kaminari使用）
- 名前、ふりがな、カテゴリ、ポジションでの検索機能

**PicksController**
- ドラフト指名記録の管理
- showアクション無し（リスト重視のインターフェース）
- ユニーク制約と確定フラグのバリデーション

**Player::ImportsController & Player::ExportsController**
- CSV操作用の名前空間化されたコントローラー
- ビジネスロジックはサービスクラスを使用

### ルーティング構造

```ruby
resources :players              # 標準RESTルート
resources :picks, except: [:show]

namespace :player do
  resource :import, only: [:new, :create]
  resource :export, only: [:new, :create]
end

root 'players#index'
```

## 重要なパターン

### Enumの使用方法
モデルではRails enumを多用しています。enumは整数ではなくシンボルで参照してください：
```ruby
# 良い例
Player.where(category: :high_school)
player.category = :university

# 避けるべき例
Player.where(category: 0)
```

### CSVインポート/エクスポート
- CSVファイルはUTF-8エンコーディング必須
- 日本語カラムヘッダーはI18n翻訳と一致
- ポジション形式: スラッシュ区切りの略称（例: "投/一"）
- すべての変換ロジックはサービスクラスで処理

### バリデーションパターン
- Pickモデルは条件付きロジックを含む複雑なユニークバリデーション
- 1位指名の支配下は重複可能（抽選シナリオ用）
- `confirmed`フラグは1位指名の支配下のみデフォルトでfalse

### 多対多リレーション
選手にポジションを割り当てる際は`position_ids`を使用：
```ruby
player.position_ids = [1, 2, 3]
# または
Player.create(name: "選手名", position_ids: [1, 2])
```

## 技術スタック

- **フレームワーク**: Rails 8.0.3
- **データベース**: SQLite3
- **フロントエンド**: Hotwire（Turbo + Stimulus）、Tailwind CSS 4.3
- **アセットパイプライン**: Propshaft
- **ページネーション**: Kaminari
- **デプロイ**: Kamal（設定済み）

## データベースに関する注意点

- シンプルさのためSQLite3を使用
- シードデータで9ポジションと12球団を作成
- 中間テーブルに外部キー制約
- 重要な関係にユニークインデックス（例: team_standingsのdraft_id + team_id）

## 最近のスキーマ変更

最近追加されたマイグレーション：
- `drafts`テーブル: 年度ごとのドラフト会議管理用
- `team_standings`テーブル: ドラフトごとのチーム順位記録用
- picksテーブルの`final_pick`フラグ（`is_completion_declaration`からリネーム）
- draftsテーブルの`virtual`フラグ（`is_virtual`からリネーム）

これらのテーブルは、基本的な選手と指名の追跡を超えた高度なドラフト管理機能をサポートします。
