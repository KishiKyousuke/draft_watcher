---
description: 現在のブランチからPull Requestを作成する
---

# Pull Request作成

現在のブランチの変更を元に、GitHub Pull Requestを作成します。

## 手順

1. **現状確認**
   以下のコマンドを並列実行して現在の状態を把握：
   - `git status` - 変更ファイルの確認
   - `git diff` - ステージング済み・未ステージの変更確認
   - `git log main..HEAD --oneline` - mainブランチからの差分コミット確認
   - `git diff main...HEAD` - mainブランチとの全差分確認
   - リモートブランチの状態確認（push済みかどうか）

2. **PRサマリーの作成**
   すべての関連コミット（最新だけでなく、ブランチの全コミット）を分析して以下を含むPRサマリーを作成：

   ### フォーマット
   ```markdown
   ## 概要
   - 変更の要点を2-3個の箇条書きで記載

   ## 変更内容
   - 主要な変更点を箇条書きで記載
   - ファイルごとまたは機能ごとにまとめる

   ## テスト計画
   - [ ] 動作確認項目1
   - [ ] 動作確認項目2

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   ```

3. **PR作成**
   以下を並列実行：
   - 必要に応じて新しいブランチを作成
   - リモートにpushされていない場合は `git push -u origin ブランチ名` でpush
   - GitHub MCPの `create_or_update_pull_request` ツールでPRを作成

   GitHub MCPツールのパラメータ:
   - `owner`: リポジトリオーナー名（git remote URLから取得）
   - `repo`: リポジトリ名（git remote URLから取得）
   - `title`: PRのタイトル
   - `body`: PRの本文（マークダウン形式）
   - `head`: ソースブランチ名（現在のブランチ）
   - `base`: ターゲットブランチ名（デフォルト: main）

4. **完了報告**
   - 作成したPRのURLをユーザーに報告
   - PR番号とタイトルを表示

## 注意事項

- **全コミットを確認** - 最新コミットだけでなく、ブランチの全変更を分析する
- **mainブランチがベース** - デフォルトでmainブランチに対してPRを作成
- **GitHub MCP使用** - `gh` CLIの代わりにGitHub MCPツールを使用
- TodoWriteツールは使用しない
- リモートにpushされていない場合は自動でpushする
- リポジトリ情報（owner/repo）は `git remote get-url origin` から取得

## 使用例

```
/create-pr
```

このコマンドで現在のブランチからmainブランチに対するPRが作成されます。
