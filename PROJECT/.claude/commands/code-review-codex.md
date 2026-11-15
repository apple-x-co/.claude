---
name: code-review-codex
description: Codex CLI の `codex review` を使用してAI駆動のコードレビューを実施。P0〜P3 の優先度付きで、作者が実際に直すべきバグを検出
allowed-tools: Bash(codex review:*)
argument-hint: [--uncommitted|--base <branch>|--commit <sha> [--title <title>]|<custom instructions>]
---

> version: 1.0.0

# Codex CLI - AI Code Review

ローカルにインストールされた Codex CLI の `codex review`（対話モードの `/review` と同じレビュー機能）を使用して、AIによるコードレビューを実施します。

## 実行するコマンド

以下のコマンドを実行してください:

```bash
# 引数がフラグ（--uncommitted / --base / --commit / --title）の場合
codex review <引数から組み立てたフラグ>

# 引数が自由記述の指示の場合
codex review - <<'REVIEW_EOF'
<指示文>
REVIEW_EOF

# 引数が指定されていない場合（デフォルト）
codex review --uncommitted
```

**シェル展開の防止**（引数がコマンドとして実行されないようにする）:
- `$ARGUMENTS` をそのままコマンドに埋め込まない。`--uncommitted` / `--base` / `--commit` / `--title` だけを取り出してフラグを組み立てる
- フラグの値（ブランチ名・SHA・タイトル）は**シングルクォート**で囲む（`'` は `'\''` に置換）
- 自由記述の指示は引数に埋め込まず、**クォート付きヒアドキュメント**で標準入力（`-`）から渡す。指示文の中に `REVIEW_EOF` だけの行がある場合は、区切り文字を別の文字列に変える

⚠️ **重要**: Codex のレビューは**数分〜10分以上**かかる場合があります。Bash ツールのタイムアウト（最大10分）で中断されないよう、`run_in_background: true` で実行し、完了通知を待ってから結果を読み取ってください。

## レビュー対象の指定

レビュー対象は以下のいずれか1つだけを指定します（同時に指定するとエラーになります）:

| 引数 | レビュー対象 |
|---|---|
| `--uncommitted` | ステージ済み・未ステージ・未追跡の変更 |
| `--base <branch>` | `<branch>` との merge-base からの差分 |
| `--commit <sha>` | 指定コミットで入った変更（`--title` でサマリーに表示するタイトルを指定可能） |
| `<custom instructions>` | 自由記述のレビュー指示（対象の差分も指示文の中で指定する） |

## Codex のレビューの仕組み

- レビューは専用のサブエージェントで実行され、承認なし（`approval_policy = never`）で `git diff` 等を実行して差分を読み取る
- レビュー用のシステムプロンプト（rubric）で、以下の条件をすべて満たすものだけを指摘する
  - 正確性・パフォーマンス・セキュリティ・保守性に実質的な影響がある
  - 個別に対処可能で、今回の変更で入ったもの（既存のバグは対象外）
  - 作者が知れば実際に直すもので、推測ではなく影響箇所を特定できる
- 些細なスタイルの指摘は、ドキュメント化された規約に反しない限り行わない
- `AGENTS.md`（`AGENTS.override.md` を優先）のルールを参照し、ルールに基づく指摘には該当ルールの参照を付ける
- 各指摘には優先度を付ける
  - **P0**: 即修正。リリースや運用、主要な利用をブロックする
  - **P1**: 緊急。次のサイクルで対応すべき
  - **P2**: 通常。いずれ修正すべき
  - **P3**: 低。あると良い
- 最後に、パッチ全体が正しいか（`patch is correct` / `patch is incorrect`）の判定と、その理由を出力する

## 出力形式

`codex review` は以下の形式のテキストを出力します:

```
<パッチ全体の判定理由（1〜3文）>

Full review comments:

- [P1] <指摘のタイトル> — <ファイルの絶対パス>:<開始行>-<終了行>
  <指摘の本文>
```

## レビュー結果の処理

1. Codex の出力を読み取る
2. パッチ全体の判定（correct / incorrect）とその理由を日本語で報告
3. 各指摘を優先度順（P0 → P1 → P2 → P3）に並べ、ファイル名と行番号を付けて日本語で報告
4. 各指摘について具体的な修正提案を提示
5. 指摘がない場合は「問題は見つかりませんでした」と報告

## 使用例

```bash
# 引数なし（デフォルトで --uncommitted を使用）
/code-review-codex

# 未コミットの変更をレビュー
/code-review-codex --uncommitted

# 特定のベースブランチと比較
/code-review-codex --base develop

# 特定のコミットをレビュー
/code-review-codex --commit abc1234

# 自由記述の指示でレビュー
/code-review-codex "main との差分をセキュリティの観点に絞ってレビューして"
```

## 自動修正ループのワークフロー

Codex を使用した推奨ワークフロー:

1. コードを書く/変更する
2. `/code-review-codex` を実行
3. 指摘された問題を分析
4. P0 および P1 の問題を修正
5. 再度 `/code-review-codex` を実行
6. P0・P1 の指摘がなくなるまで繰り返す

## Tips

- プロジェクトのルールを `CLAUDE.md` にだけ書いている場合、Codex は既定では参照しません。`-c 'project_doc_fallback_filenames=["CLAUDE.md"]'` を付けると `CLAUDE.md` もルールとして読み込みます
- レビューに使うモデルは `-c review_model="<model>"` で変更できます（未指定時はセッションのモデル）

## Codex CLI のインストール

まだインストールしていない場合:

```bash
npm install -g @openai/codex
codex login
```