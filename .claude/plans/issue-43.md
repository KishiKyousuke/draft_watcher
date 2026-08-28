# Issue #43: 選手詳細の指名結果に交渉権獲得マークをつける

## 概要

ドラ1で複数球団から入札された選手について、選手詳細ページの指名結果からはどの球団が最終的に交渉権を獲得したのか分からない。確定した指名結果に「交渉権獲得」バッジを表示し、一目で分かるようにする。

## 現状分析

- `app/views/players/show.html.erb` の「指名結果」カードでは、`@pick_results`（`Pick.official`、本番ドラフトのみ）をループし、年度・球団名・順位（支配下/育成）のバッジを1つ表示しているのみで、`confirmed`（交渉権確定）状態は表示していない。
- `Pick` モデルの `confirmed` カラムはデフォルト `true`。`before_validation :set_confirmed_default` により、支配下のドラ1指名（`draft_round == 1 && !training_player`）のみ、新規作成時に未指定なら `false` になる（抽選待ち＝交渉権未確定を表す）。それ以外のラウンド・育成指名は常に `confirmed: true`。
- 同様の確定/未確定表示は `app/views/picks/index.html.erb:45` に前例がある（「確定」「未確定」バッジ、日本語ハードコード）が、文言もコンテキスト（一覧 vs 選手詳細の交渉権獲得訴求）も異なるため、そのまま流用はしない。
- `players.show` の日本語文言は `config/locales/ja.yml` の `players.show` 配下にキーとして定義されており、`show.html.erb` は基本的に `t()` 経由で表示している。

## 実装計画

### ビュー変更
- `app/views/players/show.html.erb`
  - 指名結果ループ（`@pick_results.each do |result|` 内）で、`result.team` が存在し、かつ `result.confirmed` が true の場合に、既存の年度・球団バッジの隣（同じ `<div>` 内）に「交渉権獲得」バッジ（`span`、視認性のため既存の green 系バッジとは別トーン、例: `bg-blue-100 text-blue-800` の pill）を追加表示する。
  - `result.confirmed` が false（＝ドラ1支配下で抽選待ち）の場合はバッジを表示しない。

### 国際化（I18n）
- `config/locales/ja.yml`
  - `players.show` 配下に `negotiation_rights_acquired: 交渉権獲得` キーを追加し、ビューからは直書きせず `t('players.show.negotiation_rights_acquired')` で参照する。

### その他
- モデル・コントローラー・DBスキーマの変更は不要（`confirmed` カラムは既存）。
- ルーティング変更なし。

## テスト項目

- [ ] ドラ1・支配下・`confirmed: true` の指名結果を持つ選手の詳細ページに「交渉権獲得」バッジが表示される
- [ ] ドラ1・支配下・`confirmed: false`（抽選待ち）の指名結果には「交渉権獲得」バッジが表示されない
- [ ] ドラ2位以降、または育成指名（`confirmed` は常に `true`）の指名結果には「交渉権獲得」バッジが表示される（仕様上「確定した指名の場合は表示する」なので許容範囲）
- [ ] 指名結果が未登録（未指名）の選手の詳細ページで表示が崩れない
- [ ] 既存の年度・球団・順位バッジの表示に影響がない

## 実装時の注意点

- `confirmed: false` になり得るのは「ドラ1・支配下指名」のみ。それ以外のラウンドでは常にバッジが表示される点は仕様どおりの挙動として問題ないが、実装時に誤って「ドラ1のみバッジ表示」のような限定ロジックを入れないよう注意する。
- 日本語文言はハードコードせず `config/locales/ja.yml` にキーを追加する（既存ビューの慣習に合わせる）。
- このプロジェクトは現状テストスイートを積極的にメンテしていない（過去に `テストの削除` commitあり、`test/` 配下は空のスケルトンのみ）。新規に厚いfixture/テストを追加するのではなく、既存の運用に合わせて `rails server` 等での目視確認を実装後に行う。
