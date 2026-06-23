#!/usr/bin/env bash
# PreToolUse hook: 外向き・不可逆な操作を物理的にブロックする。
# 「外向きの行動は承認制」を、プロンプト指示ではなく決定的に強制する仕組み。
#
# 仕様: stdin に PreToolUse のイベント JSON が渡される。Bash の command を取り出し、
# 外向きパターンに一致したら exit 2（呼び出しブロック）。一致しなければ exit 0。
set -euo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
else
  cmd="$input"
fi

# 外向き・不可逆操作（公開リモートへの push / PR / リリース / リポジトリ変更）
deny_regex='git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+release[[:space:]]+create|gh[[:space:]]+repo[[:space:]]+create|gh[[:space:]]+api[[:space:]].*(-X[[:space:]]*(POST|PATCH|PUT|DELETE)|--method[[:space:]]*(POST|PATCH|PUT|DELETE))'

if printf '%s' "$cmd" | grep -qiE "$deny_regex"; then
  cat >&2 <<'MSG'
⛔ ブロック: 外向き・不可逆な操作です（git push / PR / リリース / リポジトリ変更）。

これらは「承認制」です。そのまま実行せず、次の手順を踏んでください:
  1. ローカル commit までで止める
  2. 差分サマリを共有し、承認を得る
  3. 承認後に手動で実行する
MSG
  exit 2
fi

exit 0
