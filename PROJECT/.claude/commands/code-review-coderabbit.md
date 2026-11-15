---
name: code-review-coderabbit
description: CodeRabbit CLI を使用してAI駆動の包括的なコードレビューを実施。バグ、セキュリティ脆弱性、パフォーマンス問題を検出
allowed-tools: Bash(coderabbit:*)
argument-hint: [--plain|--prompt-only] [--type all|committed|uncommitted] [--base branch|--base-commit commit]
---

> version: 1.1.0

# CodeRabbit CLI - AI Code Review

ローカルにインストールされた CodeRabbit CLI ツールを使用して、AIによる包括的なコードレビューを実施します。

## 実行するコマンド

以下のコマンドを実行してください:

```bash
# 引数が指定されている場合
coderabbit $ARGUMENTS

# 引数が指定されていない場合（デフォルト）
coderabbit --prompt-only
```

⚠️ **重要**: CodeRabbit のレビューは**7-30分以上**かかる場合があります。Bash ツールのタイムアウト（最大10分）で中断されないよう、`run_in_background: true` で実行し、完了通知を待ってから結果を読み取ってください。

## レビュー結果の処理

1. CodeRabbit の出力を読み取る
2. 検出された問題をカテゴリ別に整理して報告
3. 各問題について具体的な修正提案を提示
4. 重要度順にソート（Critical → Warning → Info）

## 使用例

```bash
# 詳細なフィードバック（人間が読みやすい）
/code-review-coderabbit --plain

# AIエージェント向けの最小出力（トークン効率的）
/code-review-coderabbit --prompt-only

# コミットされていない変更のみをレビュー
/code-review-coderabbit --plain --type uncommitted

# 特定のベースブランチと比較
/code-review-coderabbit --plain --base develop

# 現在のブランチ上の特定のコミットと比較
/code-review-coderabbit --plain --base-commit abc1234

# 引数なし（デフォルトで --prompt-only を使用）
/code-review-coderabbit
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
2. `/code-review-coderabbit --prompt-only` を実行
3. 指摘された問題を分析
4. Critical および Warning レベルの問題を修正
5. 再度 `/code-review-coderabbit --prompt-only` を実行
6. 「Review completed ✔」と表示され、重要な問題がなくなるまで繰り返す

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
