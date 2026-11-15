---
name: code-review-coderabbit
description: CodeRabbit CLI を使用してAI駆動の包括的なコードレビューを実施。バグ、セキュリティ脆弱性、パフォーマンス問題を検出
allowed-tools: Bash(coderabbit:*)
argument-hint: [--committed|--uncommitted] [--include-untracked] [--base <branch>|--base-commit <commit>] [--dir <path>] [--deep] [--fresh]
---

> version: 1.2.0

# CodeRabbit CLI - AI Code Review

ローカルにインストールされた CodeRabbit CLI ツールを使用して、AIによる包括的なコードレビューを実施します。

## 実行するコマンド

以下のコマンドを実行してください:

```bash
# 引数が指定されている場合
coderabbit review --agent <引数から組み立てたオプション>

# 引数が指定されていない場合（デフォルト）
coderabbit review --agent --include-untracked
```

**オプションの組み立て**（引数がコマンドとして実行されないようにする）:
- `$ARGUMENTS` をそのままコマンドに埋め込まない。`argument-hint` にあるオプションだけを取り出して組み立てる
- オプションの値（ブランチ名・コミット・パス）は**シングルクォート**で囲む（`'` は `'\''` に置換）
- それ以外の文字列（`;`、`&&`、`|`、`` ` ``、`$(` などを含むもの）が含まれる場合は実行せず、使えるオプションを示して指定し直してもらう

**組み合わせられないオプション**:
- `--committed` と `--uncommitted` / `--include-untracked`
- `--base` と `--base-commit`

⚠️ **重要**: CodeRabbit のレビューは**7-30分以上**かかる場合があります。Bash ツールのタイムアウト（最大10分）で中断されないよう、`run_in_background: true` で実行し、完了通知を待ってから結果を読み取ってください。

## レビュー範囲

| オプション | レビュー範囲 |
|---|---|
| （指定なし） | コミット済み・ステージ済み・追跡ファイルの未ステージの変更（未追跡ファイルは含まない） |
| `--committed` | コミット済みの変更のみ |
| `--uncommitted` | 未コミットの変更（ステージ済み・追跡ファイルの未ステージの変更） |
| `--include-untracked` | 未追跡ファイルも含める（指定なし・`--uncommitted` と組み合わせ可能） |
| `--base <branch>` | 指定ブランチとの比較 |
| `--base-commit <commit>` | 現在のブランチ上の指定コミットとの比較 |
| `--dir <path>` | 指定ディレクトリ内の変更のみ |
| `--deep` | PR レビューと同じ詳細なレビューポリシーを使う |
| `--fresh` | 前回のローカルチェックポイントを使わずにレビューする |

## レビュー結果の処理

1. CodeRabbit の出力（`--agent` の構造化された指摘）を読み取る
2. 検出された問題をカテゴリ別に整理して報告
3. 各問題について具体的な修正提案を提示
4. 重要度順にソート（Critical → Major → Minor → Trivial → Info）

## 使用例

```bash
# 引数なし（デフォルトで --include-untracked を使用）
/code-review-coderabbit

# 未コミットの変更のみをレビュー（未追跡ファイルを含む）
/code-review-coderabbit --uncommitted --include-untracked

# コミット済みの変更のみをレビュー
/code-review-coderabbit --committed

# 特定のベースブランチと比較
/code-review-coderabbit --base develop

# 現在のブランチ上の特定のコミットと比較
/code-review-coderabbit --base-commit abc1234

# 詳細なレビューポリシーでレビュー
/code-review-coderabbit --deep
```

## CodeRabbit が検出する問題

CodeRabbit CLI は以下を自動的に検出します:

- 🐛 **論理エラーとバグ**: null参照、レースコンディション、境界条件の問題
- 🔒 **セキュリティ脆弱性**: SQLインジェクション、XSS、認証の不備
- ⚡ **パフォーマンス問題**: N+1クエリ、メモリリーク、非効率なアルゴリズム
- 🏗️ **コード品質**: SOLID原則違反、コードスメル、保守性の問題
- 🧪 **テストギャップ**: 不足しているテストケース、テストカバレッジの改善点
- 📚 **ドキュメント**: 不完全または不正確なコメント、ドキュメント

## 自動修正ループのワークフロー

CodeRabbit を使用した推奨ワークフロー:

1. コードを書く/変更する
2. `/code-review-coderabbit` を実行
3. 指摘された問題を分析
4. Critical および Major の問題を修正
5. 再度 `/code-review-coderabbit` を実行
6. Critical・Major の指摘がなくなるまで繰り返す

## Tips

- 直前のレビュー結果は `coderabbit review findings` で再表示できます（再レビューせずに指摘を確認したいとき）
- プロジェクトのルールを CodeRabbit に伝えたい場合は `-c CLAUDE.md` のように追加の指示ファイルを渡せます

## CodeRabbit CLI のインストール

まだインストールしていない場合:

```bash
curl -fsSL https://cli.coderabbit.ai/install.sh | sh
coderabbit auth login
```

インストール後、シェルを再起動するか、以下を実行:
```bash
source ~/.$(basename $SHELL)rc
```

インストール済みの場合は `coderabbit update` で最新版に更新してください（上記のオプションは v0.9 系で確認）。
