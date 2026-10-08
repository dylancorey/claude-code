#!/usr/bin/env bash
# Install the status line for every Claude Code session (user level).
# Usage: bash .claude/install-statusline.sh
set -euo pipefail
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statusline.sh"
dest="$HOME/.claude/statusline.sh"
settings="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
cp "$src" "$dest"
chmod +x "$dest"
[ -f "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq --arg cmd "bash \"$dest\"" '.statusLine = {type: "command", command: $cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"
echo "Installed: $dest"
echo "Updated:   $settings"
