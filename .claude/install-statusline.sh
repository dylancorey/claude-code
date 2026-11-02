#!/usr/bin/env bash
# Install the status line for every Claude Code session (user level).
# Copies statusline.sh to ~/.claude and points ~/.claude/settings.json at it.
# Usage: bash .claude/install-statusline.sh
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required (macOS: brew install jq)" >&2
  exit 1
fi

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statusline.sh"
dest="$HOME/.claude/statusline.sh"
settings="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"
cp "$src" "$dest"
chmod +x "$dest"

[ -s "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak"
tmp=$(mktemp)
jq --arg cmd "bash \"$dest\"" '.statusLine = {type: "command", command: $cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"

echo "Installed: $dest"
echo "Updated:   $settings (backup at $settings.bak)"
