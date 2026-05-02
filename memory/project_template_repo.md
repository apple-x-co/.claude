---
name: テンプレート管理プロジェクトの概要
description: apple-x-co/.claude リポジトリはClaude Code設定ファイルのテンプレート管理プロジェクト
type: project
---

このリポジトリ（apple-x-co/.claude）はClaude Codeが読み込む設定ファイル（CLAUDE.md、コマンドファイルなど）のテンプレートを管理するプロジェクト。

- `PROJECT/` 配下：プロジェクト向けテンプレート
- `USER_HOME/` 配下：ユーザーホーム向けテンプレート

**Why:** これらのファイルはテンプレートであり、Claude Code自身がこのリポジトリ上で実行時に読み込む対象ではない。

**How to apply:** `PROJECT/CLAUDE.md` や `USER_HOME/.claude/` 内のファイルをコンテキストとして自動読み込みしないこと。あくまでテンプレートの編集・改善タスクとして扱う。