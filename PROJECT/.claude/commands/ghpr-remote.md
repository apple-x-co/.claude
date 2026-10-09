---
allowed-tools: Bash(gh:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git fetch:*), Bash(echo:*), AskUserQuestion
description: Create a GitHub Pull Request between two remote branches (default: current branch → develop, develop → main)
model: haiku
---

> version: 1.0.0

## Context

- Current branch: !`git branch --show-current`
- Remote branches: !`git branch -r`

**重要**: Context のブランチ情報はそのまま利用してよい（再取得しない）。ただし PR の**内容**の生成には、ステップ3で取得する差分のみを使用すること。

## Your task

GitHub のリモートブランチ同士（head → base）の Pull Request を作成します。`Current branch` は head / base の推奨を決めるためだけに使い、PR の内容や差分は常にリモートの状態（`origin/<base>...origin/<head>`）から生成します。push 前のローカルコミットは対象外です。

### ステップ1: ブランチ候補の整理

Context の `Remote branches`（`git branch -r` の出力）を処理対象とする（再取得しない）:
- `origin/` プレフィックスを削除
- `HEAD` を含む行（`origin/HEAD -> origin/main` など）を除外
- 重複を削除・ソート

候補が2件未満の場合は「PR を作成できるリモートブランチが足りません」と通知して終了。

### ステップ2: head / base の選択

**推奨ブランチの決定**（質問の前に決める）:
- **推奨 head**: `Current branch` がステップ1の候補に含まれ、かつ `develop` / `main` / `master` 以外ならそのブランチ。それ以外は `develop`（なければ `main` / `master`）
- **推奨 base**: 推奨 head が `develop` なら `main`（なければ `master`）。それ以外は `develop`（なければ `main` / `master`）

`AskUserQuestion` で **2つの質問を1回で**提示する:

1. 質問1: "PR の head（マージ元）ブランチを選択してください"
    - `header`: "Head branch"
    - `multiSelect`: `false`
    - `options`: 推奨 head を先頭（推奨）にし、続けてその他のブランチ（最大4件）
2. 質問2: "PR の base（マージ先）ブランチを選択してください"
    - `header`: "Base branch"
    - `multiSelect`: `false`
    - `options`: 推奨 base を先頭（推奨）にし、続けてその他のブランチ（最大4件）

推奨に該当するブランチが存在しない場合は、存在するブランチのみで候補を構成する。

選択後、head と base が同一の場合は「head と base に同じブランチは指定できません」と通知して終了。

### ステップ3: 既存 PR のチェック・差分分析（統合）

**🚨 重要制約**: 以下のコマンドの出力のみを使用して PR を生成します。

`<head>` / `<base>` にはステップ2で確定した値をリテラル文字列として代入する（shell substitution 不可）。

```bash
echo "=== EXISTING_PR ==="
gh pr list --head <head> --base <base> --state all --json number,title,state,url
echo "=== COMMITS ==="
git fetch --no-tags --quiet origin <head> <base> && git log origin/<base>..origin/<head> --pretty=tformat:"### %h %s%n%b" --reverse
echo "=== FILES ==="
git diff origin/<base>...origin/<head> --name-status
echo "=== STAT ==="
git diff origin/<base>...origin/<head> --shortstat
```

- `git diff` は三点（`...`）で、base との共通祖先から head までの変更のみを対象にする（PR の差分と一致させる）

**`gh` が認証エラーを返した場合**: 「`gh auth login` で認証してください」と通知して終了

**読み取りルール**:
- **コミット数** = `COMMITS` 区画の `### ` で始まる行数
- **変更ファイル数 / 追加・削除行数** = `STAT` 区画の `N files changed, N insertions(+), N deletions(-)`
- **変更ファイル一覧と新規/更新/削除** = `FILES` 区画の `A` / `M` / `D`
- **既存 PR** = `EXISTING_PR` 区画のうち `state` が `OPEN` または `DRAFT` のもの（`MERGED` や `CLOSED` は除外）

**差分が0コミットの場合**: 「base との差分がありません」と通知して終了

**既存 PR が見つかった場合**:

head は既にリモートにあるため、新しいコミットは既存 PR に自動で反映される。push は行わない。

`AskUserQuestion` で対応方法を選択:
- `question`: "<head> から <base> への PR が既に存在します (#番号)。どうしますか？"
- `header`: "Existing PR"
- `multiSelect`: `false`
- `options`:
    - "既存の PR のタイトル・本文を再生成する（推奨）": 最新の差分で PR 内容を更新します
    - "既存の PR を無視して新規 PR を作成する": 通常は推奨されません
    - "既存の PR をブラウザで確認する"
    - "キャンセル"

**選択に応じた処理**:
- **再生成**: ステップ4に進み、生成後に `gh pr edit <PR番号> --title "..." --body "..."` で更新。`EXISTING_PR` の `url` を表示
- **新規作成**: ステップ4に進み、新規 PR 作成フローを実行
- **ブラウザ**: `gh pr view <PR番号> --web` を実行して終了
- **キャンセル**: 「処理をキャンセルしました」と報告して終了

**既存 PR が見つからなかった場合**: そのままステップ4に進む

### ステップ4: PR 内容の生成（1つのみ）

コミット内容とファイル一覧から PR 内容を自動生成する。

**タイトルの生成ルール**:
- `develop` → `main` など長期ブランチ間のリリース PR は、含まれる主要な変更を要約する（例: `リリース: 認証機能の追加と注文API改善`）
- 1つのコミット: そのコミットの主題をベースに
- 50文字以内を目安

**本文の生成ルール**:

```markdown
## 📝 概要
[<head> → <base> の変更の要約を1-2文で記述]

## ✨ 変更内容
- **[カテゴリ名]**: [変更の簡潔な説明]
  - `ファイル名` (新規/更新/削除)
- **[カテゴリ名]**: [変更の簡潔な説明]
  - `ファイル名` (新規/更新/削除)

## 🎯 統計
- 変更ファイル: [N]件
- コミット: [N]件
- 追加: +[N]行、削除: -[N]行
```

**カテゴリ化のルール（簡易版）**:
- ファイルパスやコミットメッセージから推測
- 主要な変更種別でグループ化（機能追加、バグ修正、リファクタリングなど）
- コミット数が多い場合は 3-6 カテゴリ程度に集約し、ファイルは代表的なもののみ列挙してよい

**ファイル名の記載ルール**:
- `git diff --name-status` の出力をそのまま使用（プロジェクトルートからの相対パス）
- バッククォーテーション `` ` `` で囲む（バックスラッシュでエスケープしない）

### ステップ5: PR の作成/更新

1. **新規 PR 作成**:
   ```bash
   gh pr create \
              --head <head> \
              --base <base> \
              --title "<生成されたタイトル>" \
              --body "<生成された本文>" \
              --draft
   ```

2. **既存 PR の更新**（ステップ3で「再生成」を選択した場合）:
   ```bash
   gh pr edit <PR番号> \
              --title "<生成されたタイトル>" \
              --body "<生成された本文>"
   ```

3. **成功時の確認**:
   - 新規作成: `gh pr create` の出力から URL を読み取り、「Draft PR が正常に作成されました」と報告
   - 更新: 「PR #<番号> のタイトルと本文を更新しました」と報告
   - 「Ready にする場合は `gh pr ready <PR番号>` を実行してください」と案内

4. **エラーハンドリング**: 失敗時はエラー内容を報告し、原因候補（権限不足、head/base が存在しない、ネットワークエラー）を提示

## 重要な制約

- **全てのレスポンスを日本語で行う**
- **ローカルの状態（現在のブランチ、未 push のコミット、作業ツリー）は一切使用しない**
- **`git push` は実行しない**（リモートブランチ間の PR のため不要）
- **PR 候補は1つのみ自動生成**（選択肢なし）
- **デフォルトで Draft PR を作成**
- **既存の PR との重複をチェック**（ステップ3）

### 🚨 PR 内容生成の厳格なルール

✅ **使用してよい情報源**: ステップ3で取得した `COMMITS` / `FILES` / `STAT` 区画の出力のみ

❌ **使用禁止の情報源**: Context セクションの情報（ブランチ一覧を除く）、あなたの記憶や推測、ステップ3で取得していない情報

生成した PR 内容の全ての情報が、ステップ3の出力から確認できることを確認してください。

## Tips

- **リリース PR（develop → main）**: コミット数が多くなりがちなので、カテゴリ単位で要約する
- **Issue とのリンク**: 本文に `Closes #123` を手動で追加可能
- **push が前提**: 未 push のコミットは差分に含まれないので、先に `git push` しておく
- **詳細な PR 本文が必要な場合**: 3候補と影響範囲テーブル付きの `/ghpr-remote-advanced` を使用